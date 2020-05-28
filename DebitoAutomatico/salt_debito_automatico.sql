CREATE PROCEDURE salt_debito_automatico(
nroCliente			LIKE cliente.numero_cliente,
codigo_banco		char(3),
accion				char(1),
codigo_tarjeta		char(4),
nroTarjeta			char(16),
cbu					char(22),
tipo_cuenta			char(2))
RETURNING integer, char(100);

DEFINE codSts	int;
DEFINE descSts char(100);
DEFINE nrows	int;
	
DEFINE stsCliente			like cliente.estado_cliente;
DEFINE stsFacturacion	like cliente.estado_facturacion;
DEFINE stsTipoFpago		like cliente.tipo_fpago;

DEFINE sts_fp_banco		like forma_pago.fp_banco;
DEFINE sts_fp_nrocuenta	like forma_pago.fp_nrocuenta;
DEFINE sts_fp_sucursal	like forma_pago.fp_sucursal;
DEFINE sts_fp_cbu			like forma_pago.fp_cbu;

DEFINE codOficina			char(4);
DEFINE nroCuenta			char(22);

	LET nrows=0;
	
	IF TRIM(accion)!= 'E' OR TRIM(accion)!='R' THEN
		RETURN 1, 'Tipo de accion desconocida.';
	END IF;
	
	-- Validaciones referidas al estado del cliente TODO
	-- Estado gral del cliente
	SELECT c.estado_cliente, c.estado_facturacion, 	c.tipo_fpago,
	f.fp_banco, f.fp_nrocuenta, f.fp_sucursal, f.fp_cbu
	INTO stsCliente, stsFacturacion, stsTipoFpago,
		sts_fp_banco, sts_fp_nrocuenta, sts_fp_sucursal, sts_fp_cbu
	FROM cliente c, OUTER forma_pago f
	WHERE c.numero_cliente = nroCliente
	AND f.numero_cliente = c.numero_cliente
	AND f.fecha_activacion <= TODAY
	AND (f.fecha_desactivac IS NULL OR f.fecha_desactivac > TODAY);

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 1, 'Cliente NO Existe en el sistema.';
	END IF;

	IF stsCliente != 0 THEN
		RETURN 1, 'El Cliente NO está activo.';
	END IF;
	
	IF stsFacturacion != 0 THEN
		RETURN 1, 'El Cliente está en CICLO de Facturacion.';
	END IF;

	-- ACA procedo si solo es una baja.
	IF TRIM(accion)='R' THEN
		IF TRIM(stsTipoFpago)!= 'D' THEN
			RETURN 1, 'El Cliente es de pago NORMAL.';
		END IF;

		IF TRIM(tipo_cuenta)!= '01' THEN
			--Es una tarjeta
			IF codigo_tarjeta IS NULL THEN
				RETURN 1, 'Tipo de cuenta Tarjeta sin codigo tarjeta.';
			END IF;

			IF nroTarjeta IS NULL THEN
				RETURN 1, 'Tipo de cuenta Tarjeta sin numero tarjeta.';
			END IF;
					
			SELECT TRIM(cod_mac) INTO codOficina FROM sf_transforma
			WHERE clave = 'TARJETA'
			AND cod_sf1= TRIM(codigo_tarjeta);
			
			LET nrows = DBINFO('sqlca.sqlerrd2');
			IF nrows = 0 THEN
				RETURN 1, 'Codigo de Tarjeta no Mapeada en MAC.';
			END IF;
			
			LET nroCuenta = nroTarjeta;
		ELSE
			SELECT COUNT(*) INTO nrows
			FROM oficinas o, entidades_debito e
			WHERE o.oficina = '1330'
			AND o.oficina =  e.oficina 
			AND o.sucursal = '0000'
			AND e.tipo = 'B' 
			AND e.fecha_activacion <= TODAY
			AND (e.fecha_desactivac > TODAY OR e.fecha_desactivac IS NULL);
		
			IF nrows = 0 THEN
				RETURN 1, 'Codigo de BAnco NO Existe en MAC.';
			END IF;
					
			LET codOficina = codigo_banco;
			LET nroCuenta = cbu;
		END IF;

		EXECUTE PROCEDURE salt_debito_baja(nroCliente, tipo_cuenta, codOficina, nroCuenta) INTO codSts, descSts;
		RETURN codSts, descSts;
	
	END IF;

	-- ACA procedo si es ALTA o MODIFICACION
	IF TRIM(tipo_cuenta)!= '01' OR TRIM(tipo_cuenta)!='02' THEN
		RETURN 1, 'Tipo de cuenta desconocido.';
	END IF;
		
	IF TRIM(tipo_cuenta)!= '01' THEN
		--Es una tarjeta
		IF codigo_tarjeta IS NULL THEN
			RETURN 1, 'Tipo de cuenta Tarjeta sin codigo tarjeta.';
		END IF;

		IF nroTarjeta IS NULL THEN
			RETURN 1, 'Tipo de cuenta Tarjeta sin numero tarjeta.';
		END IF;
				
		SELECT TRIM(cod_mac) INTO codOficina FROM sf_transforma
		WHERE clave = 'TARJETA'
		AND cod_sf1= TRIM(codigo_tarjeta);
		
		LET nrows = DBINFO('sqlca.sqlerrd2');
		IF nrows = 0 THEN
			RETURN 1, 'Codigo de Tarjeta no Mapeada en MAC.';
		END IF;
		
		-- Valido la entidad y el nro.de tarjeta
		EXECUTE PROCEDURE salt_valida_tarjeta(codOficina, nroTarjeta) INTO codSts, descSts;
		
		IF codSts != 0 THEN
			RETURN codSts, descSts;
		END IF;
		
		-- Ver si es un ALTA o BAJA
		-- Grabo en solicitud de adhesion
		
		-- grabo en forma_pago
		-- registro en modif
		
		-- si corresponde actualizo cliente
		-- registro en modif

	ELSE
		--Es un banco
		IF codigo_banco IS NULL THEN
			RETURN 1, 'Tipo de cuenta Banco sin codigo banco.';
		END IF;

		IF cbu IS NULL THEN
			RETURN 1, 'Tipo de cuenta BAnco sin CBU.';
		END IF;
		
		IF codigo_banco IS NOT NULL THEN
			LET codOficina = codigo_banco;
			
			-- Valido la entidad y el cbu
			EXECUTE PROCEDURE salt_valida_banco(codOficina) INTO codSts, descSts;
			
			IF codSts != 0 THEN
				RETURN codSts, descSts;
			END IF;
		END IF;

		-- Ver si es un ALTA o BAJA
		-- Grabo en solicitud de adhesion
		-- grabo en forma_pago
		-- registro en modif
		
		-- si corresponde actualizo cliente
		-- registro en modif
	
	END IF;
	
	RETURN codSts, descSts;

END PROCEDURE;


GRANT EXECUTE ON salt_debito_automatico TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
