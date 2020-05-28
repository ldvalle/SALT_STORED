CREATE PROCEDURE salt_debito_baja(
nroCliente			LIKE cliente.numero_cliente,
tipo_cuenta			LIKE char(2),
cod_oficina			LIKE char(4),
nroCuenta			LIKE char(22))
RETURNING integer, char(100);

DEFINE codSts	int;
DEFINE descSts char(100);
DEFINE nrows	int;

DEFINE stsEntidad		char(4);
DEFINE stsNroCuenta	char(20);
DEFINE stsCbu 			char(22);

DEFINE stsElectro		char(1);

	SELECT fp_banco, fp_nrocuenta, fp_cbu
	INTO stsEntidad, stsNroCuenta, stsCBU
	FROM forma_pago
	WHERE numero_cliente = nroCliente
	AND fecha_activacion <= TODAY
	AND (fecha_desactivac IS NULL OR fecha_desactivac > TODAY);

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 1, 'El Cliente NO posee forma de pago DEBITO activa.';
	END IF;

	IF TRIM(cod_oficina) != TRIM(stsEntidad) THEN
		RETURN 1, 'Entidad Informada NO Coincide.';
	END IF;

	IF TRIM(tipo_cuenta)='01' THEN
		IF TRIM(nroCuenta)!= TRIM(stsNroCuenta) THEN
			RETURN 1, 'Nro.Cuenta Informada NO Coincide.';
		END IF;
	ELSE
		IF TRIM(nroCuenta)!= TRIM(stsCBU) THEN
			RETURN 1, 'Nro.Cuenta Informada NO Coincide.';
		END IF;	
	END IF;
	
	SELECT autoriza_adhesion
	confirma_adhesion
	INTO stsAutoriza, stsConfirma
	FROM entidades_debito
	WHERE oficina = cod_oficina
	AND fecha_activacion <= TODAY
	AND (fecha_desactivac > TODAY OR fecha_desactivac IS NULL);
	
	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 1, 'No se encontraron caracteristicas de la entidad.';
	END IF;
	
	IF TRIM(autoriza_adhesion)='N' THEN
		RETURN 1, 'Baja debe realizarce en oficina de la entidad.';
	END IF;
	
	SELECT COUNT(*) INTO nrows FROM clientes_vip v, tabla t 
	WHERE v.numero_cliente = nroCliente
	AND v.fecha_activacion <= TODAY 
	AND (v.fecha_desactivac IS NULL OR v.fecha_desactivac > TODAY) 
	AND t.nomtabla = 'SDCLIV' 
	AND t.codigo = v.motivo 
	AND t.valor_alf[4] = 'S' 
	AND t.sucursal = '0000' 
	AND t.fecha_activacion <= TODAY  
	AND ( t.fecha_desactivac >= TODAY OR t.fecha_desactivac IS NULL );	
	
	IF nrows = 0 THEN
		LET stsElectro = 'S';
	ELSE
		LET stsElectro = 'N';
	END IF;
	
	-- Graba Solicitud
	
	-- Da de Baja la FP
	
	-- Si corresponde, actualiza cliente
	
	
	
	RETURN codSts, descSts;
END PROCEDURE;

GRANT EXECUTE ON salt_debito_baja TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
