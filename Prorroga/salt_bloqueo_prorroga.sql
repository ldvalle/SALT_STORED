DROP PROCEDURE salt_bloqueo_prorroga;

CREATE PROCEDURE salt_bloqueo_prorroga(NroCliente INTEGER, Origen CHAR(2), Motivo CHAR(1), FechaIni char(8), FechaFin char(8))
    RETURNING SMALLINT AS codigo, CHAR(100) AS descripcion;

--************************************************************
--
-- PROPOSITO: Anulacion temporal de suspension
--
-- PARAMETROS:
--      Numero de Cliente
--      Origen
--      Motivo
--      Fecha Inicio
--      Fecha Fin
--
-- VALORES DE RETORNO:
--      SMALLINT : Cod.resultado: 0 -> OK
--                                1 -> No paso validacion
--                                2 -> Error
--      CHAR(100): Descripción resultado
--
--************************************************************

    DEFINE sql_err              INTEGER;
    DEFINE isam_err             INTEGER;
    DEFINE error_info           CHAR(100);
    DEFINE v_en_transaccion     INTEGER;
    DEFINE sEstadoCliente       LIKE cliente.estado_cliente;
    DEFINE iAntiguedadSaldo     LIKE cliente.antiguedad_saldo;
    DEFINE sTarifa              LIKE cliente.tarifa;
    DEFINE sSucursal            LIKE cliente.sucursal;
    DEFINE dFechaIni			DATE;
    DEFINE dFechaFin			DATE;
    DEFINE iCantDias			INTEGER;
    DEFINE miMotivo             char(2);
    DEFINE nva_fecha            DATE;

	{
    ON EXCEPTION SET sql_err, isam_err, error_info
        IF v_en_transaccion = 1 THEN
            ROLLBACK WORK;
        END IF
        RETURN 2, "Se produjo un error: " || error_info;
        --RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    
    ON EXCEPTION IN (-746) SET sql_err, isam_err, error_info
        RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    }
    
    IF FechaIni IS NOT NULL THEN
		LET dFechaIni = DATE(TO_DATE(FechaIni, '%d%m%Y')) ;
    ELSE
		LET dFechaIni = TODAY;
    END IF;
    
    IF FechaFin IS NOT NULL THEN
		LET dFechaFin = DATE(TO_DATE(FechaFin, '%d%m%Y')) ;
    ELSE
		LET dFechaFin = DATE(TO_DATE('31129999', '%d%m%Y')) ;
    END IF;
    
	 LET iCantDias = dFechaFin - dFechaIni;
	 
	 IF TRIM(Motivo) != 'C' AND TRIM(Motivo) != 'F' THEN
        RETURN 1, 'Motivo de Prorroga Desconocido';
	 END IF;
	 
	 IF TRIM(Motivo) = 'C' THEN
		IF iCantDias > 10 THEN
			LET iCantDias = 10;
		END IF
		LET miMotivo = '11';
	 END IF;

	 IF TRIM(Motivo) = 'F' THEN
		IF iCantDias > 30 THEN
			LET iCantDias = 30;
		END IF
		LET miMotivo = '01';
	 END IF;
	 
    LET v_en_transaccion = 0;

    LET sEstadoCliente, iAntiguedadSaldo, sTarifa, sSucursal =
        ( SELECT estado_cliente,
                 antiguedad_saldo,
                 tarifa,
                 sucursal
            FROM cliente
           WHERE numero_cliente = NroCliente );

    IF sEstadoCliente IS NULL THEN
        RETURN 1, "Cliente Inexistente";
    END IF

    IF sEstadoCliente <> '0' THEN
        RETURN 1, "Cliente Inactivo";
    END IF

    IF iAntiguedadSaldo < 1 THEN
        RETURN 1, "No está en situación de suspención";
    END IF


    IF ( SELECT COUNT(*) FROM corplazo
			WHERE numero_cliente = NroCliente
			AND fecha_anterior >= today ) > 0 THEN
        RETURN 1, "Cliente con Solicitud Activa de anulacion";
    END IF


    IF ( SELECT COUNT(*)
           FROM corsoco
          WHERE numero_cliente = NroCliente
            AND estado        IN ('S', 'G') ) > 0 THEN
        RETURN 1, "Cliente con Corte Individual en proceso";
    END IF


    IF ( SELECT COUNT(*)
           FROM clien_libro
          WHERE numero_cliente = NroCliente ) > 0 THEN
        RETURN 1, "Cliente con Corte Masivo en proceso";
    END IF

{
    IF ( SELECT DATE(FechaFin) - DATE(FechaIni) - t.tope_dias
           FROM corplazo_motivo m, corplazo_tope t
          WHERE m.codigo            = t.motivo
            AND m.fecha_activac    <= TODAY
            AND (m.fecha_desactivac > TODAY OR m.fecha_desactivac IS NULL)
            AND m.codigo            = miMotivo
            AND t.frecuencia        = sTarifa[3] ) <> 0 THEN
        RETURN 1, "Días de anulación no coincide con tope del motivo";
    END IF
}

    --BEGIN WORK;
    LET v_en_transaccion = 1;

    SELECT fecha_a_corte + iCantDias INTO nva_fecha FROM cliente WHERE numero_cliente = NroCliente;
    
{    
    UPDATE cliente
       SET fecha_a_corte    = nva_fecha,
           tiene_corte_rest = 'S'
     WHERE numero_cliente   = NroCliente;
}

    UPDATE cliente SET 
        fecha_a_corte    = nva_fecha
    WHERE numero_cliente   = NroCliente;

    INSERT INTO corplazo (
                    oficina,            
                    rol,                
                    cod_motivo,
                    dias,               
                    numero_cliente,     
                    sucursal,           
                    tipo,               
                    fecha_anterior,     
                    tarifa,
                    fecha_solicitud
            ) VALUES (
                    '0000',
                    'SALESFORCE',
                    miMotivo,
                    iCantDias,
                    NroCliente,
                    sSucursal,
                    'D',
                    nva_fecha,
                    sTarifa,
                    CURRENT
                    );

    --COMMIT WORK;
    --ROLLBACK WORK; --OJO

    RETURN 0, "OK";
END PROCEDURE;

GRANT EXECUTE ON salt_bloqueo_prorroga TO
superpjp, supersre, supersbl,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
