DROP PROCEDURE sfc_sam_medidores;

CREATE PROCEDURE sfc_sam_medidores(
nroClienteVjo	LIKE cliente.numero_cliente,
nroClienteNvo	LIKE cliente.numero_cliente,
nroSolicitud    LIKE solicitud.nro_solicitud)
RETURNING smallint as codigo, char(100) as descripcion;

DEFINE MED_med_numero       LIKE medidor.med_numero;        
DEFINE MED_mar_codigo       LIKE medidor.mar_codigo; 
DEFINE MED_mod_codigo       LIKE medidor.mod_codigo;
DEFINE MED_numero_cliente   LIKE medidor.numero_cliente;
DEFINE MED_med_ubic         LIKE medidor.med_ubic;
DEFINE MED_med_codubic      LIKE medidor.med_codubic;
DEFINE MED_med_estado       LIKE medidor.med_estado;
DEFINE MED_med_situacion    LIKE medidor.med_situacion;
DEFINE MED_med_precinto1    LIKE medidor.med_precinto1;
DEFINE MED_med_precinto2    LIKE medidor.med_precinto2;
DEFINE MEDCLI_fecha_alta    LIKE mecli.fecha_alta;

DEFINE nrows                integer;
DEFINE sql_err              INTEGER;
DEFINE isam_err             INTEGER;
DEFINE error_info           CHAR(100);
DEFINE auxCodRet            smallint;
DEFINE auxDescRet           char(100);

    ON EXCEPTION SET sql_err, isam_err, error_info
        RETURN 1, 'sfcSamMedidores. sqlErr '  || to_char(sql_err) || ' isamErr ' || to_char(isam_err) || ' ' || error_info;
    END EXCEPTION;

    SELECT med_numero, mar_codigo, mod_codigo,
      numero_cliente,
      med_ubic,
      med_codubic,
      med_estado,
      med_situacion,
      med_precinto1,
      med_precinto2
    INTO
      MED_med_numero,        
      MED_mar_codigo, 
      MED_mod_codigo,
      MED_numero_cliente,
      MED_med_ubic,
      MED_med_codubic,
      MED_med_estado,
      MED_med_situacion,
      MED_med_precinto1,
      MED_med_precinto2
    FROM medidor
    WHERE numero_cliente = nroClienteVjo
    AND cli_tarifa = 'T1';

    -- Hacemos MEDCLI
    SELECT fecha_alta  INTO MEDCLI_fecha_alta
    FROM medcli
    WHERE numero_cliente = nroClienteVjo
    AND mar_codigo = MED_mar_codigo
    AND mod_codigo = MED_mod_codigo
    AND med_numero = MED_med_numero;

    LET nrows = DBINFO('sqlca.sqlerrd2');
    IF nrows > 0 THEN
        -- la baja
        UPDATE medcli SET
            fecha_baja = TODAY
        WHERE numero_cliente = nroClienteVjo
        AND mar_codigo = MED_mar_codigo
        AND mod_codigo = MED_mod_codigo
        AND med_numero = MED_med_numero;
    ELSE
        -- la baja
        INSERT INTO medcli( 
          med_numero,
          mar_codigo,
          mod_codigo,
          numero_cliente,
          tarifa,
          fecha_alta,
          fecha_baja 
        )VALUES(
          MED_med_numero,
          MED_mar_codigo,
          MED_mod_codigo,
          nroClienteVjo,
          'T1',
          TODAY,
          TODAY);
    END IF;
    
    -- El Alta
    INSERT INTO medcli( 
      med_numero,
      mar_codigo,
      mod_codigo,
      numero_cliente,
      tarifa,
      fecha_alta
    )VALUES(
      MED_med_numero,
      MED_mar_codigo,
      MED_mod_codigo,
      nroClienteNvo,
      'T1',
      TODAY);
   
    -- Actualizo MEDIDOR
    UPDATE medidor SET
      med_codubic = MED_med_codubic,
      numero_cliente = nroClienteNvo,
      med_fecdesp = TODAY,
      usuario_modif = 'SALESFORCE',
      fecha_modificacion = CURRENT 
    WHERE med_numero = MED_med_numero
    AND mar_codigo = MED_mar_codigo
    AND mod_codigo = MED_mod_codigo
    AND cli_tarifa = 'T1';

    -- Actualizar STOCK
    INSERT INTO stock (
      mar_tipo,
      mar_codigo,
      mod_codigo,
      stk_numero,
      stk_tdesde,
      stk_desde,
      stk_thasta,
      stk_hasta,
      stk_fecha,
      mat_equiva,
      stk_estado,
      doc_tipo,
      doc_numero,
      mat_cambio,
      stk_afecta,
      stk_urgen,
      stk_nrocliente,
      stk_tipodocom,
      stk_precinto1,
      stk_precinto2,
      usuario_modif,
      fecha_modificacion 
    )VALUES(
      'M',
      MED_mar_codigo,
      MED_mod_codigo,
      MED_med_numero,
      'C',
      to_char(nroClienteVjo),
      'C',
      to_char(nroClienteNvo),
      CURRENT,
      '          ', --10 espacios en blanco
      MED_med_situacion,
      '999',
      'SOLSUMIN',
      MED_med_estado,
      'N',
      'N',
      to_char(nroClienteNvo),
      nroSolicitud,
      MED_med_precinto1,
      MED_med_precinto2,
      'SALESFORCE',
      CURRENT );
    
        
    RETURN 0, 'OK';   
END PROCEDURE;


GRANT EXECUTE ON sfc_sam_medidores TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
