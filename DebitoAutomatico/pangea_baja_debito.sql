DROP PROCEDURE pangea_baja_debito;

CREATE PROCEDURE pangea_baja_debito(NroCliente INTEGER, TipoCuenta CHAR(2), CodBanco CHAR(4), CBU CHAR(22), ClaseTarjeta CHAR(4), NroTarjeta CHAR(20))
    RETURNING SMALLINT AS codigo, CHAR(100) AS descripcion;

--************************************************************
--
-- PROPOSITO: Baja de Débito Automático
--
-- PARAMETROS:
--      Numero de Cliente
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
    DEFINE v_en_transaccion     INTEGER;
    DEFINE sCorteRest           LIKE cliente.tiene_corte_rest;
    DEFINE sCambiosRest         LIKE cliente.tiene_cambios_rest;
    DEFINE iValModif            INTEGER;
    DEFINE sErrModif            CHAR(100);
    DEFINE sValMarca            CHAR(2);
    DEFINE sCodMarca            CHAR(3);
    DEFINE sDescMarca           CHAR(50);
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

	 DEFINE stsEntidad		char(4);
	 DEFINE stsNroCuenta		char(20);
	 DEFINE stsCbu 			char(22);

    ON EXCEPTION SET sql_err, isam_err, error_info
        IF v_en_transaccion = 1 THEN
            ROLLBACK WORK;
        END IF
        RETURN 2, "Cliente en proceso. Intente mas tarde: " || error_info;
        --RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    {
    ON EXCEPTION IN (-746) SET sql_err, isam_err, error_info
        RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;
    }

    LET v_en_transaccion = 0;

-------------------
	SELECT fp_banco, fp_nrocuenta, fp_cbu
	INTO stsEntidad, stsNroCuenta, stsCBU
	FROM forma_pago
	WHERE numero_cliente = nroCliente
	AND fecha_activacion <= TODAY
	AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY);

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 0, 'El Cliente NO posee forma de pago DEBITO activa.';
	END IF;
	
{   --- Se quito para que puedan cambiar de debito a debito
	IF TRIM(TipoCuenta)=='01' THEN
		IF stsCBU IS NOT NULL THEN
			RETURN 1, 'Tipo de Entidad Informada NO Coincide.';
		END IF;
		IF TRIM(ClaseTarjeta)!= TRIM(stsEntidad) THEN
			RETURN 1, 'Entidad Informada NO Coincide.';
		END IF;	
		IF TRIM(NroTarjeta)!= TRIM(stsNroCuenta) THEN
			RETURN 1, 'Nro.de tarjeta NO Coincide.';
		END IF;		
	ELSE
		IF stsCBU IS NULL THEN
			RETURN 1, 'Tipo de Entidad Informada NO Coincide.';
		END IF;
		IF TRIM(CodBanco)!= TRIM(stsEntidad) THEN
			RETURN 1, 'Entidad Informada NO Coincide.';
		END IF;	
		IF TRIM(CBU)!= TRIM(stsCBU) THEN
			RETURN 1, 'CBU NO Coincide.';
		END IF;	
	END IF;
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
        LET sDatoAnterior= 'D|' || sBanco || '|' || sTipoCuenta || '|' || sNroCuenta || '|' || sSucursalBco;
    ELSE
        LET sBanco       = CodBanco;
        LET sTipoCuenta  = '9';
        LET sNroCuenta   = SUBSTRING( CBU FROM 12 FOR 11 );
        LET sSucursalBco = SUBSTRING( CBU FROM 5  FOR 4  );
        LET sCBU         = CBU;
        LET sDatoAnterior= 'D|' || sBanco || '|' || sCBU;
    END IF

    LET sDatoNuevo = 'N';

    --BEGIN WORK;
    LET v_en_transaccion = 1;

    UPDATE forma_pago
       SET fecha_desactivac = TODAY
     WHERE numero_cliente    = NroCliente
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


    EXECUTE PROCEDURE valida_marca_corte(NroCliente, 'DEB') INTO sValMarca, sCodMarca, sDescMarca;

    LET sCorteRest   = NULL;
    LET sCambiosRest = NULL;
    
    IF sValMarca = 'SI' THEN
        LET sCorteRest   = 'N';
        LET sCambiosRest = 'N';
    END IF
    
    IF sCorteRest IS NOT NULL THEN
        UPDATE cliente
           SET tiene_corte_rest   = sCorteRest,
               tiene_cambios_rest = sCambiosRest,
               tipo_fpago         = 'N',
               tiene_cobro_rec    = 'S',
               tiene_cobro_int    = 'S'
         WHERE numero_cliente     = NroCliente;
    ELSE
        UPDATE cliente
           SET tipo_fpago         = 'N',
               tiene_cobro_rec    = 'S',
               tiene_cobro_int    = 'S'
         WHERE numero_cliente     = NroCliente;
    END IF


    --EXECUTE PROCEDURE ivr_nroorden_modif('0000') INTO sNroOrden;
    let sNroOrden = '0';

    EXECUTE PROCEDURE pangea_ins_modif(NroCliente, 'MOD', sNroOrden, 'SALESFORCE', 'A', '70', sDatoAnterior, sDatoNuevo, 'SALT-T1', 'FUSE') INTO iValModif, sErrModif;

    IF iValModif <> 0 THEN
        RAISE EXCEPTION -746, 0, sErrModif;
    END IF


    IF sCorteRest IS NOT NULL THEN
        --EXECUTE PROCEDURE ivr_nroorden_modif('0000') INTO sNroOrden;
        let sNroOrden     = '0';
        LET sDatoNuevo    = sCorteRest;
        LET sDatoAnterior = 'S';
    
        EXECUTE PROCEDURE pangea_ins_modif(NroCliente, 'MOD', sNroOrden, 'SALESFORCE', 'A', '53', sDatoAnterior, sDatoNuevo, 'SALT-T1', 'FUSE') INTO iValModif, sErrModif;
    
        IF iValModif <> 0 THEN
            RAISE EXCEPTION -746, 0, sErrModif;
        END IF
    END IF

    --COMMIT WORK;
    --ROLLBACK WORK; --OJO

    RETURN 0, "OK" ;
END PROCEDURE;

--EXECUTE pangea_baja_debito
GRANT EXECUTE ON pangea_baja_debito TO
superpjp, supersre, supersbl,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
