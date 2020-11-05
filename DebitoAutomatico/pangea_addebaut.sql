DROP PROCEDURE pangea_addebaut;

CREATE PROCEDURE pangea_addebaut(NroCliente INTEGER, Solicitud CHAR(1), TipoCuenta CHAR(2), CodBanco CHAR(4), CBU CHAR(22), ClaseTarjeta CHAR(4), NroTarjeta CHAR(20))
    RETURNING INTEGER AS codigo, CHAR(100) AS descripcion;

--************************************************************
--
-- PROPOSITO: Alta y Baja de Débito Automático
--
-- PARAMETROS:
--      Numero de Cliente
--      Solicitud = Accion
--      Tipo de Cuenta
--      Código de Banco
--      CBU
--      Clase de Tarjeta
--      Número de Tarjeta de Crédito
--
-- VALORES DE RETORNO:
--      SMALLINT : Cod.resultado: 0 -> OK
--                                1 -> No paso validacion
--                                2 -> Error
--      CHAR(100): Descripción resultado
--
-- AUTOR: Pablo Privitera
-- FECHA DE CREACION: 08/2019
--
--************************************************************

    DEFINE sql_err              INTEGER;
    DEFINE isam_err             INTEGER;
    DEFINE error_info           CHAR(100);
    DEFINE sEstadoCliente       LIKE cliente.estado_cliente;
    DEFINE sEstadoFacturacion   LIKE cliente.estado_facturacion;
    DEFINE sDVCliente           LIKE cliente.dv_numero_cliente;
    DEFINE sCorteRest           LIKE cliente.tiene_corte_rest;
    DEFINE ivalCodigo           INTEGER;
    DEFINE iValProced           INTEGER;
    DEFINE sErrProced           CHAR(100);
    DEFINE codOficina			char(4);
    DEFINE nrows				int;
    DEFINE iCantReg             int;
    DEFINE mi_codigo_banco      char(4);
    
    {
    ON EXCEPTION SET sql_err, isam_err, error_info
        RETURN 2, "Se produjo un error: " || error_info;
        --RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    
    ON EXCEPTION IN (-746) SET sql_err, isam_err, error_info
        RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    }
    
    IF Solicitud <> 'E' AND Solicitud <> 'R' THEN
        RETURN 1, 'Tipo Solicitud incorrecta';
    END IF
    
    IF TipoCuenta <> '01' AND TipoCuenta <> '02' THEN
        RETURN 1, 'Tipo Cuenta incorrecta';
    END IF
    
    IF (TipoCuenta = '01' AND (ClaseTarjeta IS NULL OR NroTarjeta IS NULL)) OR
       (TipoCuenta = '02' AND (CodBanco IS NULL OR CBU IS NULL) )THEN
        RETURN 1, 'Paremetros incorrectos';
    END IF

    IF TipoCuenta = '02' AND LENGTH(CBU) <> 22 THEN 
        RETURN 1, 'Cant.Dígitos de CBU incorrecto';
    END IF
    IF TipoCuenta = '02' AND LENGTH(CodBanco) <> 4 THEN 
        RETURN 1, 'Cant.Dígitos Cod Banco incorrecto';
    END IF

    

    LET sEstadoCliente, sEstadoFacturacion, sDVCliente, sCorteRest =
        ( SELECT estado_cliente, estado_facturacion, dv_numero_cliente, tiene_corte_rest
            FROM cliente
           WHERE numero_cliente = NroCliente );

    IF sEstadoCliente <> '0' THEN
        RETURN 1, 'Cliente Inactivo';
    END IF

    IF sEstadoFacturacion <> '0' THEN
        RETURN 1, 'Cliente en Ciclo de Facturación';
    END IF

	IF TRIM(TipoCuenta)= '01' THEN
		--Es una tarjeta
		SELECT TRIM(cod_mac) INTO codOficina FROM sf_transforma
		WHERE clave = 'TARJETA'
		AND cod_sf1= TRIM(ClaseTarjeta);
		
		LET nrows = DBINFO('sqlca.sqlerrd2');
		IF nrows = 0 THEN
			RETURN 1, 'Codigo de Tarjeta no Mapeada en MAC.';
		END IF;

        LET ivalCodigo =
            ( SELECT e.dig_nro_cuenta
                FROM entidades_debito e, oficinas o
            WHERE e.oficina           = o.oficina
                AND e.oficina           = codOficina
                AND e.tipo              = 'T'
                AND e.autoriza_adhesion = 'S'
                AND e.confirma_adhesion = 'N'
                AND e.fecha_activacion <= TODAY
                AND (e.fecha_desactivac > TODAY OR e.fecha_desactivac IS NULL)
                AND o.sucursal          = '0000'
                AND o.vigente           = 'S'
                AND o.tipo              = 'D' );
		
	ELSE
		-- Es cuenta Bancaria
		LET mi_codigo_banco = CodBanco[2,4];
		
		SELECT e.dig_nro_cuenta, e.oficina INTO ivalCodigo, codOficina
            FROM entidades_debito e, oficinas o
           WHERE e.oficina           = o.oficina
             AND e.cod_ofi_bcra      = TRIM(mi_codigo_banco)
             AND e.tipo              = 'B'
             AND e.autoriza_adhesion = 'S'
             AND e.confirma_adhesion = 'N'
             AND e.fecha_activacion <= TODAY
             AND (e.fecha_desactivac > TODAY OR e.fecha_desactivac IS NULL)
             AND o.sucursal          = '0000'
             AND o.vigente           = 'S'
             AND o.tipo              = 'D';
	END IF;
{
    LET ivalCodigo =
        ( SELECT e.dig_nro_cuenta
            FROM entidades_debito e, oficinas o
           WHERE e.oficina           = o.oficina
             AND e.oficina           = codOficina
             AND e.tipo              = DECODE(TipoCuenta, '01', 'T', '02', 'B')
             AND e.autoriza_adhesion = 'S'
             AND e.confirma_adhesion = 'N'
             AND e.fecha_activacion <= TODAY
             AND (e.fecha_desactivac > TODAY OR e.fecha_desactivac IS NULL)
             AND o.sucursal          = '0000'
             AND o.vigente           = 'S'
             AND o.tipo              = 'D' );
}

    IF ivalCodigo IS NULL THEN
        RETURN 1, 'Codigo Banco/Tarjeta incorrecto o Entidad no autoriza adhesión directa.';
    END IF

    IF TipoCuenta = '01' THEN 
        IF ivalCodigo <> LENGTH(NroTarjeta) THEN
            RETURN 1, 'Cant.Dígitos de Número de Cuenta incorrecto';
        END IF
   END IF

   LET iCantReg = (SELECT COUNT(*) FROM forma_pago WHERE numero_cliente = NroCliente AND fecha_activacion = TODAY);
   
    IF Solicitud = 'E' THEN
        IF iCantReg > 0 then
            RETURN 1, 'El Cliente ya tiene un alta el dia de hoy.';
        END IF;
        {
        -- Se agrega para dar de baja la existente y de alta la nueva
        IF ( SELECT COUNT(*)
                FROM forma_pago
            WHERE numero_cliente = NroCliente
                AND fecha_activacion <= TODAY
                AND (fecha_desactivac > TODAY OR fecha_desactivac IS NULL) ) > 0 THEN
            
            --EXECUTE PROCEDURE pangea_baja_debito(NroCliente, TipoCuenta, CodBanco, CBU, codOficina, NroTarjeta) INTO iValProced, sErrProced;
            EXECUTE PROCEDURE pangea_baja_debito(NroCliente, TipoCuenta, codOficina, CBU, codOficina, NroTarjeta) INTO iValProced, sErrProced;
        
            IF iValProced != 0 THEN
                RETURN 1, sErrProced;
            END IF
        END IF        
        }
        
        --EXECUTE PROCEDURE pangea_alta_debito(NroCliente, TipoCuenta, CodBanco, CBU, codOficina, NroTarjeta, sDVCliente, sCorteRest) INTO iValProced, sErrProced;
        EXECUTE PROCEDURE pangea_alta_debito(NroCliente, TipoCuenta, codOficina, CBU, codOficina, NroTarjeta, sDVCliente, sCorteRest) INTO iValProced, sErrProced;
    
        IF iValProced != 0 THEN
            RETURN 1, sErrProced;
        END IF
    ELSE
        --EXECUTE PROCEDURE pangea_baja_debito(NroCliente, TipoCuenta, CodBanco, CBU, codOficina, NroTarjeta) INTO iValProced, sErrProced;
        EXECUTE PROCEDURE pangea_baja_debito(NroCliente, TipoCuenta, codOficina, CBU, codOficina, NroTarjeta) INTO iValProced, sErrProced;
    
        IF iValProced != 0 THEN
            RETURN 1, sErrProced;
        END IF
    END IF

    RETURN 0, 'OK' ;
END PROCEDURE;

--EXECUTE pangea_addebaut
GRANT EXECUTE ON pangea_addebaut TO
superpjp, supersre, supersbl,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
