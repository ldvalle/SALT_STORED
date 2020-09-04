DROP PROCEDURE salt_update_postal;

CREATE PROCEDURE salt_update_postal(
nro_cliente				LIKE cliente.numero_cliente,
pos_calle				LIKE postal.dp_nom_calle,
pos_numeroCalle		LIKE postal.dp_nro_dir,
pos_piso					LIKE postal.dp_piso_dir,
pos_depto				LIKE postal.dp_depto_dir,
codigoPostal			LIKE postal.dp_cod_postal,
pos_localidad			LIKE postal.dp_nom_localidad,
pos_partido				LIKE postal.dp_nom_partido,
pos_provincia			LIKE postal.dp_nom_provincia,
pos_entreCalle1		LIKE postal.dp_nom_entre,
pos_entreCalle2		LIKE postal.dp_nom_entre1)
RETURNING SMALLINT AS codigo, CHAR(100) AS descripcion;

	DEFINE sql_err              INTEGER;
	DEFINE isam_err             INTEGER;
	DEFINE error_info           CHAR(100);

	ON EXCEPTION SET sql_err, isam_err, error_info
		RETURN 2, "ERROR DB: - " || sql_err || ' - ' || isam_err || ' - ' || error_info; 
	END EXCEPTION;

	UPDATE postal SET
		dp_nom_provincia = pos_provincia,
		dp_nom_partido = pos_partido,
		dp_nom_localidad = pos_localidad,
		dp_nom_calle = pos_calle,
		dp_nro_dir = pos_numeroCalle,
		dp_piso_dir = pos_piso,
		dp_depto_dir = pos_depto,
		dp_cod_postal = codigoPostal,
		dp_nom_entre = pos_entreCalle1,
		dp_nom_entre1 = pos_entreCalle2
	WHERE numero_cliente = nro_cliente;
	
	RETURN 0, 'OK';
END PROCEDURE;

GRANT EXECUTE ON salt_update_postal TO
superpjp, supersre, supersbl,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
