DROP PROCEDURE sfc_mover_precintos;

CREATE PROCEDURE sfc_mover_precintos(
nroClienteVjo	LIKE cliente.numero_cliente,
nroClienteNvo	LIKE cliente.numero_cliente,
nroMedidor      LIKE medid.numero_medidor,
marcaMedidor    LIKE medid.marca_medidor,
modeloMedidor   LIKE medid.modelo_medidor)
RETURNING smallint as codigo, char(100) as descripcion;

DEFINE PRT_serie            LIKE prt_precintos.serie;
DEFINE PRT_numero_precinto  LIKE prt_precintos.numero_precinto; 
DEFINE PRT_numero_medidor   LIKE prt_precintos.numero_medidor; 
DEFINE PRT_marca            LIKE prt_precintos.marca; 
DEFINE PRT_modelo           LIKE prt_precintos.modelo;
DEFINE PRT_corr_evento      LIKE prt_precintos.corr_evento;
DEFINE PRT_sucursal         LIKE prt_precintos.sucursal;
DEFINE PRT_funcion          LIKE prt_precintos.funcion;

DEFINE nrows                integer;
DEFINE sql_err              INTEGER;
DEFINE isam_err             INTEGER;
DEFINE error_info           CHAR(100);
DEFINE auxCodRet            smallint;
DEFINE auxDescRet           char(100);

    ON EXCEPTION SET sql_err, isam_err, error_info
        RETURN 1, 'sfcMoverPrecintos. sqlErr '  || to_char(sql_err) || ' isamErr ' || to_char(isam_err) || ' ' || error_info;
    END EXCEPTION;


    SELECT serie, numero_precinto, numero_medidor, marca, modelo
    INTO
        PRT_serie, PRT_numero_precinto, PRT_numero_medidor, 
        PRT_marca, PRT_modelo
    FROM prt_precintos 
    WHERE numero_cliente = nroClienteVjo
    AND estado_actual  = '08';
    
	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 0, 'OK';
	END IF;

    IF PRT_numero_medidor != nroMedidor OR PRT_marca != marcaMedidor OR PRT_modelo != modeloMedidor THEN
        -- hacemos la baja inconsistente
        UPDATE prt_precintos SET
        estado_actual = '07', 
        corr_evento = corr_evento + 1, 
        fecha_estado = CURRENT 
        WHERE serie = PRT_serie 
        AND numero_precinto =  PRT_numero_precinto;

        SELECT corr_evento, sucursal, funcion
        INTO PRT_corr_evento, PRT_sucursal, PRT_funcion
        FROM prt_precintos
        WHERE serie = PRT_serie
        AND numero_precinto  = PRT_numero_precinto;
        
        EXECUTE PROCEDURE sfc_ins_prt_eventos_hist(PRT_serie, PRT_numero_precinto, nroMedidor, marcaMedidor, 
            modeloMedidor, PRT_corr_evento, 'BI', 'Correccion antes 08', '07', PRT_sucursal, PRT_funcion)
            INTO auxCodRet, auxDescRet;
            
        IF auxCodRet != 0 THEN
            RETURN auxCodRet, auxDescRet;
        END IF;
    ELSE
        -- Mudo los precintos
        UPDATE prt_precintos SET
        corr_evento = corr_evento + 2, 
        numero_cliente = nroClienteNvo,
        fecha_estado = CURRENT 
        WHERE serie = PRT_serie
        AND numero_precinto = PRT_numero_precinto;
  
        SELECT corr_evento, sucursal, funcion
        INTO PRT_corr_evento, PRT_sucursal, PRT_funcion
        FROM prt_precintos
        WHERE serie = PRT_serie
        AND numero_precinto  = PRT_numero_precinto;

        EXECUTE PROCEDURE sfc_ins_prt_eventos_hist(PRT_serie, PRT_numero_precinto, nroMedidor, marcaMedidor, 
            modeloMedidor, PRT_corr_evento - 1, 'II', 'Baja cliente por CT', '80', PRT_sucursal, PRT_funcion)
            INTO auxCodRet, auxDescRet;
            
        IF auxCodRet != 0 THEN
            RETURN auxCodRet, auxDescRet;
        END IF;

        EXECUTE PROCEDURE sfc_ins_prt_eventos_hist(PRT_serie, PRT_numero_precinto, nroMedidor, marcaMedidor, 
            modeloMedidor, PRT_corr_evento, 'II', 'Cod. Estado Anterior:80', '08', PRT_sucursal, PRT_funcion)
            INTO auxCodRet, auxDescRet;
            
        IF auxCodRet != 0 THEN
            RETURN auxCodRet, auxDescRet;
        END IF;
        
    END IF;
    
END PROCEDURE;


GRANT EXECUTE ON sfc_mover_precintos TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
