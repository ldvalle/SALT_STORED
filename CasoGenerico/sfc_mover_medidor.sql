DROP PROCEDURE sfc_mover_medidor;

CREATE PROCEDURE sfc_mover_medidor(
nroClienteVjo	LIKE cliente.numero_cliente,
nroClienteNvo	LIKE cliente.numero_cliente,
nroSolicitud    integer)
RETURNING smallint as codigo, char(100) as descripcion;

DEFINE MEDID_numero_medidor integer;
DEFINE MEDID_marca_medidor  char(3);
DEFINE MEDID_modelo_medidor char(2);
DEFINE MEDID_fecha_ult_insta date;
DEFINE MEDID_correlativo    smallint;
DEFINE MEDID_constante      smallfloat;
DEFINE MEDID_ultima_lect_activa float;
DEFINE MEDID_ultima_lect_reac   float;
DEFINE MEDID_tipo_medidor   char(1);

DEFINE ULTMED_tipo1         varchar(1,0);
DEFINE ULTMED_tipo2         varchar(1,0);
DEFINE ULTMED_tipo3         varchar(1,0);
DEFINE ULTMED_tipo4         varchar(1,0);
DEFINE ULTMED_tipo5         varchar(1,0);
DEFINE ULTMED_tipo6         varchar(1,0);
DEFINE ULTMED_valor1        varchar(10,1);
DEFINE ULTMED_valor2        varchar(10,1);
DEFINE ULTMED_valor3        varchar(10,1);
DEFINE ULTMED_valor4        varchar(10,1);
DEFINE ULTMED_valor5        varchar(10,1);
DEFINE ULTMED_valor6        varchar(10,1);
DEFINE ULTMED_fecha1        date;
DEFINE ULTMED_fecha2        date;
DEFINE ULTMED_fecha3        date;
DEFINE ULTMED_fecha4        date;
DEFINE ULTMED_fecha5        date;
DEFINE ULTMED_fecha6        date;
DEFINE ULTMED_anio_fabrica  smallint;
DEFINE ULTMED_marca_censo   char(1);

DEFINE CLIENTE_fecha_ultima_lect date;

DEFINE nrows                integer;
DEFINE sql_err              INTEGER;
DEFINE isam_err             INTEGER;
DEFINE error_info           CHAR(100);


    ON EXCEPTION SET sql_err, isam_err, error_info
        RETURN 1, 'sfcMoverMedidor. sqlErr '  || to_char(sql_err) || ' isamErr ' || to_char(isam_err) || ' ' || error_info;
        --RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;

    SELECT fecha_ultima_lect INTO CLIENTE_fecha_ultima_lect
    FROM cliente WHERE numero_cliente = nroClienteVjo; 
    
    -- Levantamos MEDID
    SELECT numero_medidor,
      marca_medidor,
      modelo_medidor,
      fecha_ult_insta,
      correlativo,
      constante,
      ultima_lect_activa,
      ultima_lect_reac,
      tipo_medidor
    INTO
      MEDID_numero_medidor,
      MEDID_marca_medidor,
      MEDID_modelo_medidor,
      MEDID_fecha_ult_insta,
      MEDID_correlativo,
      MEDID_constante,
      MEDID_ultima_lect_activa,
      MEDID_ultima_lect_reac,
      MEDID_tipo_medidor
    FROM medid 
    WHERE numero_cliente = nroClienteVjo
    AND estado = 'I'

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 1, 'Cliente sin MEDID activo.';
	END IF;

    -- Levantar y crear ULTMED
    SELECT tipo1,
      tipo2,
      tipo3,
      tipo4,
      tipo5,
      tipo6,
      valor1,
      valor2,
      valor3,
      valor4,
      valor5,
      valor6,
      fecha1,
      fecha2,
      fecha3,
      fecha4,
      fecha5,
      fecha6,
      anio_fabrica,
      marca_censo
    INTO
      ULTMED_tipo1,
      ULTMED_tipo2,
      ULTMED_tipo3,
      ULTMED_tipo4,
      ULTMED_tipo5,
      ULTMED_tipo6,
      ULTMED_valor1,
      ULTMED_valor2,
      ULTMED_valor3,
      ULTMED_valor4,
      ULTMED_valor5,
      ULTMED_valor6,
      ULTMED_fecha1,
      ULTMED_fecha2,
      ULTMED_fecha3,
      ULTMED_fecha4,
      ULTMED_fecha5,
      ULTMED_fecha6,
      ULTMED_anio_fabrica,
      ULTMED_marca_censo
    FROM ultmed
    WHERE numero_medidor = MEDID_numero_medidor
    AND marca_medidor = MEDID_marca_medidor
    AND modelo_medidor = MEDID_modelo_medidor;
    
	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
        INSERT INTO ultmed 
        (tipo1, valor1, fecha1, 
          numero_medidor, marca_medidor, modelo_medidor
        )VALUES( '1', nroClienteNvo, TODAY,
          MEDID_nro_medidor, MEDID_marca_medidor, MEDID_modelo_medidor);
    ELSE
        UPDATE ultmed SET 
        tipo1 = '1', "
        tipo2 = ULTMED_tipo4,
        tipo3 = ULTMED_tipo5,
        tipo4 = ULTMED_tipo5,
        tipo5 = ULTMED_tipo6,
        tipo6 = ULTMED_valor1,
        valor1 = nroClienteNvo, 
        valor2 = ULTMED_valor4,
        valor3 = ULTMED_valor5,
        valor4 = ULTMED_valor6,
        valor5 = ULTMED_fecha1,
        valor6 = ULTMED_fecha2,
        fecha1 = TODAY, 
        fecha2 = ULTMED_fecha4,
        fecha3 = ULTMED_fecha5,
        fecha4 = ULTMED_fecha6,
        fecha5 = ULTMED_anio_fabrica,
        fecha6 = ULTMED_marca_censo
        WHERE numero_medidor = MEDID_nro_medidor
        AND marca_medidor = MEDID_marca_medidor
        AND modelo_medidor = MEDID_modelo_medidor;
	END IF;
                                                      
    RETURN retCodigo, retDescripcion;

    -- Crear la hislec tipo 7 para cliente nuevo
    INSERT INTO hislec (
      numero_cliente, 
      corr_facturacion, 
      numero_medidor, 
      marca_medidor,
      constante,
      lectura_facturac,
      lectura_terreno,
      consumo,
      tipo_lectura,
      fecha_lectura, 
      correl_contador
    )VALUES(
      nroClienteNvo, 
      0, 
      MEDID_numero_medidor,
      MEDID_marca_medidor,
      MEDID_constante,
      MEDID_ultima_lect_activa,
      MEDID_ultima_lect_activa,
      0,
      '7', 
      NVL(CLIENTE_fecha_ultima_lect, TODAY),
      MEDID_correlativo);
    
    IF MEDID_tipo_medidor = 'R' THEN
        INSERT INTO hislec_reac 
        (
          numero_cliente, 
          corr_facturacion, 
          numero_medidor, 
          marca_medidor, 
          lectu_factu_reac, 
          lectu_terreno_reac, 
          consumo_reac, 
          tipo_lectura, 
          fecha_lectura, 
          coseno_phi
        )VALUES()
          nroClienteNvo,
          0,
          MEDID_numero_medidor,
          MEDID_marca_medidor,
          MEDID_ultima_lect_reac,
          MEDID_ultima_lect_reac,
          0,
          '7',
          NVL(CLIENTE_fecha_ultima_lect, TODAY),
          100 );
    END IF;
    
    -- Insertar medidor a la baja
    INSERT INTO enre_fec_ins_bajas ( 
        numero_cliente, 
        numero_medidor, 
        marca_medidor, 
        modelo_medidor, 
        fecha_ult_insta 
    )VALUES(
        nroClienteVjo,
        MEDID_numero_medidor,
        MEDID_marca_medidor,
        MEDID_modelo_medidor,
        MEDID_fecha_ult_insta
    );
     
    -- Hacemos los precintos
    
    -- Teminamos de transferir el medidor
    
    
END PROCEDURE;


GRANT EXECUTE ON sfc_mover_medidor TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
