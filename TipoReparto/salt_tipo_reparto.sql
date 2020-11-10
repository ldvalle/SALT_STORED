DROP PROCEDURE salt_tipo_reparto;

CREATE PROCEDURE salt_tipo_reparto(
nro_cliente				LIKE cliente.numero_cliente,
sol_tipo_reparto		CHAR(4),
pos_calle				LIKE postal.dp_nom_calle,
pos_numeroCalle		LIKE postal.dp_nro_dir,
pos_piso					LIKE postal.dp_piso_dir,
pos_depto				LIKE postal.dp_depto_dir,
codigoPostal			LIKE postal.dp_cod_postal,
pos_localidad			LIKE postal.dp_nom_localidad,
pos_partido				LIKE postal.dp_nom_partido,
pos_provincia			char(3),
pos_entreCalle1		LIKE postal.dp_nom_entre,
pos_entreCalle2		LIKE postal.dp_nom_entre1)
RETURNING SMALLINT AS codigo, CHAR(100) AS descripcion;

	DEFINE miProvincia		LIKE postal.dp_nom_provincia;
	DEFINE miTipoReparto		char(10);
	DEFINE sts_cliente		integer;
	DEFINE sts_factura		integer;
	DEFINE sts_tipo_reparto	LIKE cliente.tipo_reparto;
	DEFINE nrows				integer;
	DEFINE stsCodigo			smallint;
	DEFINE stsDescri			char(100);
	
	-- Tipo Reparto Digital lo reboto con OK
	IF TRIM(sol_tipo_reparto)= '01' THEN
		RETURN 0, 'OK';
	END IF;
    
	IF TRIM(sol_tipo_reparto)!= '02' AND TRIM(sol_tipo_reparto)!= '04' AND TRIM(sol_tipo_reparto)!= '05' THEN
		RETURN 1, 'Tipo Reparto desconocido.';
	END IF;
    
   -- si va a postal validar datos
   IF TRIM(sol_tipo_reparto)='04' THEN
		IF TRIM(pos_calle) IS NULL OR TRIM(pos_numeroCalle) IS NULL OR codigoPostal IS NULL THEN
			RETURN 1, 'Datos insuficientes para Reparto Postal.';
		END IF;
		IF TRIM(pos_localidad) IS NULL OR TRIM(pos_partido) IS NULL OR TRIM(pos_provincia) IS NULL THEN
			RETURN 1, 'Datos insuficientes para Reparto Postal.';
		END IF;  
			SELECT TRIM(descripcion) INTO miProvincia FROM sap_transforma
			WHERE clave = 'REGION'
			AND cod_sap = TRIM(pos_provincia);

			LET nrows = DBINFO('sqlca.sqlerrd2');
			IF nrows = 0 THEN
				RETURN 1, 'Provincia NO codificada para SAP.';
			END IF;
	END IF;
   
	SELECT estado_cliente, estado_facturacion, tipo_reparto 
			INTO sts_cliente, sts_factura, sts_tipo_reparto 
			FROM cliente WHERE numero_cliente = nro_cliente;
	
	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 1, 'El Cliente NO existe en el sistema T1.';
	END IF;
	
	IF sts_cliente != 0 THEN
		RETURN 1, 'El Cliente NO está activo.';
	END IF;

	IF sts_cliente != 0 THEN
		RETURN 1, 'El Cliente está en ciclo de facturacion.';
	END IF;

	-- de normal a postal
	IF TRIM(sts_tipo_reparto)= 'NORMAL' AND TRIM(sol_tipo_reparto)= '04' THEN
		-- crear postal
		EXECUTE PROCEDURE salt_alta_postal(nro_cliente, pos_calle, pos_numeroCalle, 
			pos_piso, pos_depto, codigoPostal, pos_localidad, 
			pos_partido, miProvincia, pos_entreCalle1, pos_entreCalle2) INTO stsCodigo, stsDescri;
			
		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;
			
		-- actualizar cliente
		UPDATE cliente SET
			tipo_reparto = 'POSTAL'
		WHERE numero_cliente = nro_cliente;
		
		-- registra modif
		EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '93', 'NORMAL', 'POSTAL', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;

		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;

	-- de normal a braile	
	ELIF TRIM(sts_tipo_reparto)= 'NORMAL' AND TRIM(sol_tipo_reparto)= '02' THEN
		-- actualizar cliente
		UPDATE cliente SET
			tipo_reparto = 'BRAILE'
		WHERE numero_cliente = nro_cliente;
		
		-- registra modif
		EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '93', 'NORMAL', 'BRAILE', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;

		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;
				
	-- de postal a normal
	ELIF TRIM(sts_tipo_reparto)= 'POSTAL' AND TRIM(sol_tipo_reparto)= '05' THEN
		-- baja postal
		DELETE FROM postal WHERE numero_cliente = nro_cliente;
		
		-- actualizar cliente
		UPDATE cliente SET
			tipo_reparto = 'NORMAL'
		WHERE numero_cliente = nro_cliente;		
		
		-- registra modif
		EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '93', 'POSTAL', 'NORMAL', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;

		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;		
		
        -- Quitar marca de Digital Sin Papel
        LET nrows=0;
        
        SELECT COUNT(*) INTO nrows FROM clientes_digital 
        WHERE numero_cliente = nro_cliente
        AND fecha_alta <= CURRENT
        AND (fecha_baja IS NULL OR fecha_baja > CURRENT)
        AND sin_papel = 'S';
        
        IF nrows > 0 THEN
          UPDATE clientes_digital SET
          sin_papel = 'N',
          rol_modif = 'SALESFORCE',
          fecha_modif = CURRENT
          WHERE numero_cliente = nro_cliente
          AND fecha_alta <= CURRENT
          AND (fecha_baja IS NULL OR fecha_baja > CURRENT)
          AND sin_papel = 'S';
        
          -- registra modif
          EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '269', 'S', 'N', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;
        
        END IF;
        

	-- de postal a braile
	ELIF TRIM(sts_tipo_reparto)= 'POSTAL' AND TRIM(sol_tipo_reparto)= '02' THEN
		-- baja postal
		DELETE FROM postal WHERE numero_cliente = nro_cliente;
		
		-- actualizar cliente
		UPDATE cliente SET
			tipo_reparto = 'BRAILE'
		WHERE numero_cliente = nro_cliente;		
		
		-- registra modif
		EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '93', 'POSTAL', 'BRAILE', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;

		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;	
		
    -- de postal a postal
	ELIF TRIM(sts_tipo_reparto)= 'POSTAL' AND TRIM(sol_tipo_reparto)= '04' THEN
		-- actualizar postal
		EXECUTE PROCEDURE salt_update_postal(nro_cliente, pos_calle, pos_numeroCalle, 
			pos_piso, pos_depto, codigoPostal, pos_localidad, 
			pos_partido, miProvincia, pos_entreCalle1, pos_entreCalle2) INTO stsCodigo, stsDescri;
			
		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;

		-- registra modif
		EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '98', 'POSTAL', 'POSTAL', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;

		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;
		
	-- de braile a normal
	ELIF TRIM(sts_tipo_reparto)= 'BRAILE' AND TRIM(sol_tipo_reparto)= '05' THEN
		-- actualizar cliente
		UPDATE cliente SET
			tipo_reparto = 'NORMAL'
		WHERE numero_cliente = nro_cliente;		
		
		-- registra modif
		EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '93', 'BRAILE', 'NORMAL', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;

		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;

        -- Quitar marca de Digital Sin Papel
        LET nrows=0;
        
        SELECT COUNT(*) INTO nrows FROM clientes_digital 
        WHERE numero_cliente = nro_cliente
        AND fecha_alta <= CURRENT
        AND (fecha_baja IS NULL OR fecha_baja > CURRENT)
        AND sin_papel = 'S';
        
        IF nrows > 0 THEN
          UPDATE clientes_digital SET
          sin_papel = 'N',
          rol_modif = 'SALESFORCE',
          fecha_modif = CURRENT
          WHERE numero_cliente = nro_cliente
          AND fecha_alta <= CURRENT
          AND (fecha_baja IS NULL OR fecha_baja > CURRENT)
          AND sin_papel = 'S';
        
          -- registra modif
          EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '269', 'S', 'N', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;
        
        END IF;
		
	-- de braile a postal
	ELIF TRIM(sts_tipo_reparto)= 'BRAILE' AND TRIM(sol_tipo_reparto)= '04' THEN
		-- crear postal
		EXECUTE PROCEDURE salt_alta_postal(nro_cliente, pos_calle, pos_numeroCalle, 
			pos_piso, pos_depto, codigoPostal, pos_localidad, 
			pos_partido, miProvincia, pos_entreCalle1, pos_entreCalle2) INTO stsCodigo, stsDescri;
			
		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;
				
		-- actualizar cliente
		UPDATE cliente SET
			tipo_reparto = 'POSTAL'
		WHERE numero_cliente = nro_cliente;
				
		-- registra modif
		EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '93', 'BRAILE', 'POSTAL', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;

		IF stsCodigo != 0 THEN
			RETURN stsCodigo, stsDescri;
		END IF;
        
    -- de Normal a Normal        
    ELIF TRIM(sts_tipo_reparto)= 'NORMAL' AND TRIM(sol_tipo_reparto)= '05' THEN 
        -- Quitar marca de Digital Sin Papel
        LET nrows=0;
        
        SELECT COUNT(*) INTO nrows FROM clientes_digital 
        WHERE numero_cliente = nro_cliente
        AND fecha_alta <= CURRENT
        AND (fecha_baja IS NULL OR fecha_baja > CURRENT)
        AND sin_papel = 'S';
        
        IF nrows > 0 THEN
          UPDATE clientes_digital SET
          sin_papel = 'N',
          rol_modif = 'SALESFORCE',
          fecha_modif = CURRENT
          WHERE numero_cliente = nro_cliente
          AND fecha_alta <= CURRENT
          AND (fecha_baja IS NULL OR fecha_baja > CURRENT)
          AND sin_papel = 'S';
        
          -- registra modif
          EXECUTE PROCEDURE pangea_ins_modif(nro_cliente, 'MOD', 0, 'SALESFORCE', 'A', '269', 'S', 'N', 'SALT-T1', 'FUSE') INTO stsCodigo, stsDescri;
        
        END IF;
    
	ELSE
		RETURN 1, "Operacion desconocida [" || TRIM(sts_tipo_reparto) || "] [" || TRIM(sol_tipo_reparto) || "]";
	END IF;
	

    RETURN 0, "Operacion OK";
END PROCEDURE;

GRANT EXECUTE ON salt_tipo_reparto TO
superpjp, supersre, supersbl,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
