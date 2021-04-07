DROP PROCEDURE sfc_mover_clientes;

CREATE PROCEDURE sfc_mover_clientes(
nroClienteVjo	LIKE cliente.numero_cliente,
nroClienteNvo	LIKE cliente.numero_cliente,
nroSolicitud    integer)
RETURNING smallint as codigo, char(100) as descripcion;

DEFINE retCodigo smallint;
DEFINE retDescripcion  char(100);
DEFINE nrows        integer;
DEFINE codRetorno   integer;
DEFINE descRetorno  char(100);

DEFINE dv_nvo_cliente char(1);

DEFINE ss_nombre    varchar(40, 0); 
DEFINE ss_tip_doc   varchar(6, 0);   
DEFINE ss_nro_doc   float;
DEFINE ss_origen_doc    varchar(6, 0);
DEFINE ss_tarifa        varchar(5, 0);
DEFINE ss_cod_postal    smallint;
DEFINE ss_obs_dir       varchar(60, 0);
DEFINE ss_tipo_iva      varchar(3, 0);
DEFINE ss_tipo_cliente  varchar(4, 0);
DEFINE ss_tipo_venc     varchar(6, 0);
DEFINE ss_nro_cuit      varchar(11, 0);
DEFINE ss_ciiu          varchar(4, 0);
DEFINE ss_cod_propiedad varchar(6, 0);
DEFINE ss_tipo_sum      varchar(2, 0);
DEFINE ss_pot_cont_hp   float;

DEFINE sql_err              INTEGER;
DEFINE isam_err             INTEGER;
DEFINE error_info           CHAR(100);

    ON EXCEPTION SET sql_err, isam_err, error_info
        RETURN 1, 'sfcMoverCliente. sqlErr '  || to_char(sql_err) || ' isamErr ' || to_char(isam_err) || ' ' || error_info;
        --RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;

    -- Movemos los clientes
    INSERT INTO cliente_temp
    SELECT * FROM CLIENTE 
    WHERE numero_cliente = nroClienteVjo;
    
    UPDATE cliente_temp SET 
    numero_cliente = nroClienteNvo,
    tiene_prorrateo = '3'
    WHERE numero_cliente = nroClienteVjo;
    
    INSERT INTO cliente SELECT * FROM CLIENTE_TEMP 
    WHERE numero_cliente = nroClienteNvo;

    DELETE FROM cliente_temp
    WHERE numero_cliente = nroClienteNvo;
    
    -- Damos de baja el viejo
    UPDATE cliente SET
    estado_cliente = '1',  
    estado_suministro = '1', 
    tiene_corte_rest = 'N', 
    cantidad_medidores = 0, 
    motret = '000006' 
    where numero_cliente = nroClienteVjo;
    
    EXECUTE PROCEDURE salt_graba_modif(nroClienteVjo, '58', 'SALESFORCE', 'INCORPORACION', 'Activo', 'Baja Cliente')
		INTO codRetorno, descRetorno;
    
    IF codRetorno != 0 THEN
        RETURN codRetorno, descRetorno;
    END IF;
    
    -- Actualizar Data Nvo.Cliente
    EXECUTE PROCEDURE sfc_get_dvcliente(nroClienteNvo) INTO dv_nvo_cliente;
    
    -- Levantamos lo que tenemos de la solicitud
    SELECT s.nombre, s.tip_doc, s.nro_doc, s.origen_doc, s.tarifa, s.cod_postal, s.obs_dir,
        s.tipo_iva, s.tipo_cliente, s.tipo_venc, s.nro_cuit, s.ciiu, s.cod_propiedad, s.tipo_sum, s.pot_cont_hp
    INTO
        ss_nombre, ss_tip_doc, ss_nro_doc, ss_origen_doc, ss_tarifa, ss_cod_postal, ss_obs_dir, ss_tipo_iva,
        ss_tipo_cliente, ss_tipo_venc, ss_nro_cuit, ss_ciiu, ss_cod_propiedad, ss_tipo_sum, ss_pot_cont_hp
    FROM solicitud s
    WHERE s.nro_solicitud = nro_solicitud;

    UPDATE cliente SET
      dv_numero_cliente = dv_nvo_cliente,
      nombre = ss_nombre,
      tip_doc = ss_tip_doc,
      nro_doc = ss_nro_doc,
      origen_doc = ss_origen_doc,
      tarifa = ss_tarifa,
      cod_postal = ss_cod_postal,
      obs_dir = ss_obs_dir,
      tipo_iva = ss_tipo_iva,
      tipo_cliente = ss_tipo_cliente,
      tipo_vencimiento = ss_tipo_venc,
      rut = ss_nro_cuit,
      tipo_sum = ss_tipo_sum,
      actividad_economic = ss_ciiu,
      cod_propiedad = ss_cod_propiedad,
      potencia_inst_fp = ss_pot_cont_hp,
      potencia_cont_fp = ss_pot_cont_hp,
      potencia_inst_hp = ss_pot_cont_hp,
      potencia_cont_hp = ss_pot_cont_hp,
      potencia_contrato = ss_pot_cont_hp,
      corr_facturacion = 0,
      corr_pagos = 0,
      corr_convenio = 0,
      corr_refacturacion = 0,
      corr_corte = 0,
      corr_factint = 0,
      cant_estimac_suces = 0,
      cant_estimaciones = 0,
      meses_cerrados = 0,
      fecha_a_corte = 219206,
      fecha_vig_conv = null,
      fecha_clave_tarifa = fecha_ultima_lect,
      estado_cliente = 2,
      categoria = '00',
      estado_cobrabilida = '1',
      tiene_convenio = 'N',
      tiene_calma = 'N',
      tiene_cnr = 'N',
      tiene_corte_rest = 'N',
      tiene_cobro_rec = 'S',
      tiene_cobro_int = 'S',
      tiene_cambios_rest = 'N',
      ind_ret_medidor = 'N',
      tiene_refacturac = 'N',
      tipo_fpago = 'N',
      tipo_reparto = 'NORMAL',
      saldo_actual = 0,
      saldo_int_acum = 0,
      saldo_imp_no_suj_i = 0,
      saldo_imp_suj_int = 0,
      antiguedad_saldo = 0,
      nro_beneficiario = nroClienteVjo,
      coseno_phi = 100,
      fecha_anticipo = null,
      valor_anticipo = 0,
      recargo_tension = 0,
      motret = '',
      recurso_propio = 'N', 
      corr_factint = 0,
      cuenta_conver = null,
      tiene_caduc_manual = 'N'
    WHERE numero_cliente = nroClienteNvo;
    
    RETURN retCodigo, retDescripcion;

END PROCEDURE;


GRANT EXECUTE ON sfc_mover_clientes TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
