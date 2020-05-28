CREATE PROCEDURE salt_comprobante_pago(
nroCliente			LIKE cliente.numero_cliente,
saldo_exigible		float,
saldo_no_exigible	float,
producto_servicio	float,
tasa				float,
conve				float,
total    			float,
flexible			float)
RETURNING integer as codigo, char(100) as descripcion, char(60) as codigoBarras1, char(60) as codigoBarras2;

DEFINE codSts	int;
DEFINE descSts char(100);
DEFINE barra1	char(60);
DEFINE barra2	char(60);
DEFINE iBarra	smallint;
DEFINE monto1	float;
DEFINE monto2	float;
DEFINE dv_barra1 char(1);
DEFINE dv_barra2 char(1);
DEFINE sucur_emi	char(4);
DEFINE area_emi   char(4);
DEFINE rol_emi		char(20);
DEFINE motivo	char(2);

DEFINE dv_cliente			like cliente.dv_numero_cliente;
DEFINE sucur_clie			like cliente.sucursal;
DEFINE sector_clie			like cliente.sector;
DEFINE tarifa_clie			like cliente.tarifa;
DEFINE tipoSuministro		like cliente.tipo_sum;
DEFINE stsCliente			like cliente.estado_cliente;
DEFINE stsFacturac			like cliente.estado_facturacion;
DEFINE stsCob				like cliente.estado_cobrabilida;
DEFINE sValor				like tabla.valor_alf;
DEFINE fecha_fmt			char(6);
DEFINE saldo_cliente		float;
DEFINE nroComprobante		char(3);
DEFINE iValor				int;
DEFINE iCantVeces			int;

	LET iBarra=0;
	LET rol_emi='SALESFORCE';
	LET motivo='10';
	
	-- estado gral del cliente
	SELECT c.dv_numero_cliente, c. sucursal, c.sector, c.tarifa, c.tipo_sum,
	c.estado_cliente, c.estado_facturacion, c.estado_cobrabilida, 
	t1.valor_alf, to_char(today, '%y%m%d'),
	c.saldo_actual + c.saldo_int_acum + c.saldo_imp_no_suj_i + c.saldo_imp_suj_int - c.valor_anticipo
	INTO
		dv_cliente,
		sucur_clie,
		sector_clie,
		tarifa_clie,
		tipoSuministro,
		stsCliente,
		stsFacturac,
		stsCob,
		sValor,
		fecha_fmt,
		saldo_cliente
	FROM cliente c, tabla t1
	WHERE c.numero_cliente = nroCliente
	AND t1.nomtabla = 'ESTCOB'
	AND t1.sucursal = '0000'
	AND t1.codigo = c.estado_cobrabilida
	AND t1.fecha_activacion <= TODAY
	AND (t1.fecha_desactivac IS NULL OR t1.fecha_desactivac > TODAY);

	-- Validaciones
	EXECUTE PROCEDURE salt_valida_compropago(nroCliente, tarifa_clie, stsCliente, stsFacturac,
		stsCob, sValor, tipoSuministro) INTO codSts, descSts;
	
	IF codSts !=0 THEN
		RETURN codSts, descSts, '', '';
	END IF;

	-- Acomodamientos
	IF TRIM(stsCob) = 'A' THEN
		LET motivo = '30';
	END IF;	

	IF TRIM(stsCob) = 'B' THEN
		LET motivo = '45';
	END IF;	

	IF saldo_cliente <= 0 THEN
		LET motivo = '13';
		
		
	END IF;
	-- datos emision
	SELECT r.area, s.sucursal
	INTO
		area_emi,
		sucur_emi
	FROM xnear2:rol r, sucar s
	WHERE r.rol = rol_emi
	AND s.area = r.area;
	
	-- Empiezo a armar
	IF saldo_exigible IS NOT NULL THEN
		LET iBarra=1;
		LET monto1 = round(saldo_exigible,2);
		LET monto2 = round((saldo_cliente - saldo_exigible),2);
	END IF;

	IF saldo_no_exigible IS NOT NULL THEN
		LET iBarra=0;
		LET monto1 = round(saldo_no_exigible,2);
	END IF;
	
	IF producto_servicio IS NOT NULL THEN
		LET iBarra=0;
		LET monto1 = round(producto_servicio,2);
	END IF;

	IF tasa IS NOT NULL THEN
		LET iBarra=0;
		LET monto1 = round(tasa,2);
	END IF;

	IF conve IS NOT NULL THEN
		LET iBarra=0;
		LET monto1 = round(conve,2);
	END IF;

	IF total IS NOT NULL THEN
		LET iBarra=0;
		LET monto1 = round(total,2);
	END IF;
	
	IF flexible IS NOT NULL THEN
		LET iBarra=0;
		LET monto1 = round(flexible, 2);
	END IF;
	
	IF monto1 IS NULL THEN
		RETURN 1, 'El monto 1 es nulo', '', '';
	END IF;
	
	-- Sacar el nro.de comprobante
	EXECUTE PROCEDURE salt_get_nro_logcomprob(nroCliente, motivo, 'COMPAG', sucur_emi)
		INTO codSts, descSts, nroComprobante;
	
	IF codSts != 0 THEN
		RETURN codSts, descSts, '', '';
	END IF;
	
	INSERT INTO log_comprob (
		numero_cliente, 
		tipo_comprob,
		nro_comprob,
		monto_comprob,
		rol_emisor,
		fecha_emision,
		area_emision,	
		sucursal_emision,
		ip_emisor
	)VALUES(
		nroCliente,
		motivo,
		nroComprobante,
		monto1,
		rol_emi,
		TODAY,
		area_emi,
		sucur_emi,
		'190.9.120.1');
		
	INSERT INTO log_comprob_emit (
		numero_cliente, 
		tipo_comprob, 
		nro_comprob,
		fecha_emision, 
		motivo_emision
	)VALUES (
		nroCliente,
		motivo,
		nroComprobante,
		TODAY,
		'Solic.desde SALESFORCE');
		
	-- Armar Barra 1
	EXECUTE PROCEDURE salt_arma_barra (sucur_clie, sector_clie, nroCliente, monto1, fecha_fmt, nroComprobante, motivo)
		INTO barra1, dv_barra1;
	
	IF iBarra=1 THEN
		IF monto2 IS NULL THEN
			RETURN 1, 'El monto 2 es nulo', '', '';
		END IF;
		-- Sacar el nro.de comprobante
		EXECUTE PROCEDURE salt_get_nro_logcomprob(nroCliente, motivo, 'COMPAG', sucur_emi)
			INTO codSts, descSts, nroComprobante;
		
		IF codSts != 0 THEN
			RETURN codSts, descSts, '', '';
		END IF;
	
		INSERT INTO log_comprob (
			numero_cliente, 
			tipo_comprob,
			nro_comprob,
			monto_comprob,
			rol_emisor,
			fecha_emision,
			area_emision,	
			sucursal_emision,
			ip_emisor
		)VALUES(
			nroCliente,
			motivo,
			nroComprobante,
			monto2,
			rol_emi,
			TODAY,
			area_emi,
			sucur_emi,
			'190.9.120.1');
			
		INSERT INTO log_comprob_emit (
			numero_cliente, 
			tipo_comprob, 
			nro_comprob,
			fecha_emision, 
			motivo_emision
		)VALUES (
			nroCliente,
			motivo,
			nroComprobante,
			TODAY,
			'Solic.desde SALESFORCE');	
	
		EXECUTE PROCEDURE salt_arma_barra (sucur_clie, sector_clie, nroCliente, monto2, fecha_fmt, nroComprobante, motivo)
			INTO barra2, dv_barra2;
	ELSE
		LET barra2 = '';
	END IF;

	RETURN codSts, trim(descSts), trim(barra1), trim(barra2);

END PROCEDURE;


GRANT EXECUTE ON salt_comprobante_pago TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
