DROP PROCEDURE pangea_alta_debito;

CREATE PROCEDURE pangea_alta_debito(NroCliente INTEGER, TipoCuenta CHAR(2), CodBanco CHAR(4), CBU CHAR(22), ClaseTarjeta CHAR(4), NroTarjeta CHAR(20), sDVCliente LIKE cliente.dv_numero_cliente, sCorteRest LIKE cliente.tiene_corte_rest)
    RETURNING SMALLINT AS codigo, CHAR(100) AS descripcion;

--************************************************************
--
-- PROPOSITO: Alta de Débito Automático
--
-- PARAMETROS:
--      Numero de Cliente
--      Tipo de Cuenta
--      Código de Banco
--      CBU
--      Clase de Tarjeta
--      Número de Tarjeta de Crédito
--      DV Cliente
--      Corte Rest
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
    DEFINE v_en_transaccion     INTEGER;
    DEFINE iValCBU              INTEGER;
    DEFINE iErrCBU              INTEGER;
    DEFINE iValModif            INTEGER;
    DEFINE sErrModif            CHAR(100);
    DEFINE sBanco               LIKE solicitud_adhpag.fp_banco;
    DEFINE sTipoCuenta          LIKE solicitud_adhpag.fp_tipocuenta;
    DEFINE sNroCuenta           LIKE solicitud_adhpag.fp_nrocuenta;
    DEFINE sSucursalBco         LIKE solicitud_adhpag.fp_sucursal;
    DEFINE sCBU                 LIKE solicitud_adhpag.fp_cbu;
    DEFINE sDatoAnterior        LIKE modif.dato_anterior;
    DEFINE sDatoNuevo           LIKE modif.dato_nuevo;
    DEFINE sNroOrden            LIKE modif.numero_orden;
    
    DEFINE g_area		char(4);
    DEFINE g_sucur	char(4);
    DEFINE nrows		int;

    ON EXCEPTION SET sql_err, isam_err, error_info
        IF v_en_transaccion = 1 THEN
            ROLLBACK WORK;
        END IF
        RETURN 2, "Cliente en proceso. Intente mas tarde.: " || error_info;
        --RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    
    {
    ON EXCEPTION IN (-746) SET sql_err, isam_err, error_info
        RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    }
    
    LET v_en_transaccion = 0;
{   -- se quitó para que puedan cambiar de debito a debito
    IF ( SELECT COUNT(*)
            FROM forma_pago
           WHERE numero_cliente    = NroCliente
             AND fecha_activacion <= TODAY
             AND (fecha_desactivac > TODAY OR fecha_desactivac IS NULL) ) > 0 THEN
        
        RETURN 1, "Cliente adherido a Debito Automatico";
    END IF


    IF ( SELECT COUNT(*)
            FROM solicitud_adhpag
           WHERE numero_cliente = NroCliente ) > 0 THEN
        RETURN 1, "Cliente con Solicitud Previa";
    END IF

}
    IF TipoCuenta = '02' THEN
    	EXECUTE PROCEDURE ivr_val_cbu(CBU, CodBanco) INTO iValCBU, iErrCBU;

        IF iValCBU = 0 THEN
            RETURN 1, "CBU Inválido";
        END IF
    ELSE
        IF ( SELECT COUNT(*)
               FROM prefijo_debito
              WHERE oficina = ClaseTarjeta
                AND prefijo = SUBSTRING(NroTarjeta FROM 1 FOR LENGTH( prefijo ) ) ) = 0 THEN
            RETURN 1, "Prefijo Tarjeta incorrecto";
        END IF;
    END IF

{
    LET sTipoCuenta =
        ( SELECT codigo
            FROM tabla 
           WHERE sucursal          = '0000'
             AND nomtabla          = 'BANCUE' 
             AND fecha_activacion <= TODAY 
             AND (fecha_desactivac > TODAY OR fecha_desactivac IS NULL) );
}

	SELECT r.area, s.sucursal INTO g_area, g_sucur FROM rol r, sucar s
	WHERE r.rol = 'SALESFORCE'
	AND s.area = r.area;
	
	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 1, 'No se encontró rol SALESFORCE.';
	END IF;


    IF TipoCuenta = '01' THEN
        LET sBanco       = ClaseTarjeta;
        LET sTipoCuenta  = '2';
        LET sNroCuenta   = NroTarjeta;
        LET sSucursalBco = '0';
        LET sCBU         = NULL;
        LET sDatoNuevo   = 'D|' || sBanco || '|' || sTipoCuenta || '|' || sNroCuenta || '|' || sSucursalBco;
    ELSE
        LET sBanco       = CodBanco;
        LET sTipoCuenta  = '9';
        LET sNroCuenta   = SUBSTRING( CBU FROM 12 FOR 11 );
        LET sSucursalBco = SUBSTRING( CBU FROM 5  FOR 4  );
        LET sCBU         = CBU;
        LET sDatoNuevo   = 'D|' || sBanco || '|' || sCBU;        
    END IF
    
    LET sDatoAnterior = 'N';
    
    --BEGIN WORK;
    LET v_en_transaccion = 1;

    -- Esto es para permitir cambio de debito en un solo paso
    UPDATE forma_pago set
    fecha_desactivac = TODAY
    WHERE numero_cliente = NroCliente
    AND fecha_activacion <= TODAY
    AND (fecha_desactivac > TODAY OR fecha_desactivac IS NULL);

    INSERT INTO solic_adhpag_el (
                    numero_cliente,
                    dv_cliente,
                    codigo_movimiento,
                    fp_banco,
                    fp_tipocuenta,
                    fp_nrocuenta,
                    fp_sucursal,
                    fecha_solicitud,
                    rol_creacion,
                    sucursal_ede,
                    codigo_extraccion,
                    fecha_extraccion,
                    fp_cbu,
                    fecha_eliminacion,
                    rol_eliminacion)
            SELECT numero_cliente,
                   dv_cliente,
                   codigo_movimiento,
                   fp_banco,
                   fp_tipocuenta,
                   fp_nrocuenta,
                   fp_sucursal,
                   fecha_solicitud,
                   rol_creacion,
                   sucursal_ede,
                   codigo_extraccion,
                   fecha_extraccion,
                   fp_cbu,
                   TODAY,
                   'SALESFORCE'
              FROM solicitud_adhpag
             WHERE numero_cliente    = NroCliente
               AND codigo_movimiento = '42';


    DELETE FROM solicitud_adhpag
     WHERE numero_cliente    = NroCliente
       AND codigo_movimiento = '42';    
    
    -- fin baja forzada
    
    INSERT INTO solicitud_adhpag (
                    numero_cliente,
                    dv_cliente,
                    codigo_movimiento,
                    fp_banco,
                    fp_tipocuenta,
                    fp_nrocuenta,
                    fp_sucursal,
                    fecha_solicitud,
                    rol_creacion,
                    sucursal_ede,
                    codigo_extraccion,
                    fecha_extraccion,
                    fp_cbu
            ) VALUES (
                    NroCliente, 
                    sDVCliente, 
                    '42',
                    sBanco,
                    sTipoCuenta,
                    sNroCuenta,
                    sSucursalBco,
                    TODAY,
                    'SALESFORCE',
                    g_sucur,
                    'S',
                    TODAY,
                    sCBU);


    INSERT INTO forma_pago (
                    numero_cliente,
                    fp_nrocuenta,
                    fp_banco,
                    fp_tipocuenta,
                    fp_sucursal,
                    fecha_activacion,
                    fp_cbu
            ) VALUES (
                    NroCliente,
                    sNroCuenta,
                    sBanco,
                    sTipoCuenta,
                    sSucursalBco,
                    TODAY,
                    sCBU);


    UPDATE cliente 
       SET tipo_fpago       = 'D',
           tiene_corte_rest = 'S',
           tiene_cobro_rec  = 'N',
           tiene_cobro_int  = 'N'
     WHERE numero_cliente   = NroCliente;


    --EXECUTE PROCEDURE ivr_nroorden_modif('0000') INTO sNroOrden;
    let sNroOrden = '0';

    EXECUTE PROCEDURE pangea_ins_modif(NroCliente, 'MOD', sNroOrden, 'SALESFORCE', 'A', '70', sDatoAnterior, sDatoNuevo, 'SALT-T1', 'FUSE') INTO iValModif, sErrModif;

    IF iValModif <> 0 THEN
        RAISE EXCEPTION -746, 0, sErrModif;
    END IF


    --EXECUTE PROCEDURE ivr_nroorden_modif('0000') INTO sNroOrden;
    let sNroOrden     = '0';
    LET sDatoAnterior = sCorteRest;
    LET sDatoNuevo    = 'S';

    EXECUTE PROCEDURE pangea_ins_modif(NroCliente, 'MOD', sNroOrden, 'SALESFORCE', 'A', '53', sDatoAnterior, sDatoNuevo, 'SALT-T1', 'FUSE') INTO iValModif, sErrModif;

    IF iValModif <> 0 THEN
        RAISE EXCEPTION -746, 0, sErrModif;
    END IF

    --COMMIT WORK;
    --ROLLBACK WORK; --OJO

    RETURN 0, "OK" ;
END PROCEDURE;

--EXECUTE pangea_alta_debito
GRANT EXECUTE ON pangea_alta_debito TO
superpjp, supersre, supersbl,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
