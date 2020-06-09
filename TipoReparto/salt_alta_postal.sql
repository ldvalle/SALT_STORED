DROP PROCEDURE salt_alta_postal;

CREATE PROCEDURE salt_alta_postal(
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

	INSERT INTO postal (
		numero_cliente,
		dp_nom_provincia,
		dp_nom_partido,
		dp_nom_localidad,
		dp_nom_calle,
		dp_nro_dir,
		dp_piso_dir,
		dp_depto_dir,
		dp_cod_postal,
		dp_nom_entre,
		dp_nom_entre1
	)VALUES(
		nro_cliente,
		pos_provincia,
		pos_partido,
		pos_localidad,
		pos_calle,
		pos_numeroCalle,
		pos_piso,
		pos_depto,
		codigoPostal,
		pos_entreCalle1,
		pos_entreCalle2 );


	RETURN 0, 'OK';
END PROCEDURE;

GRANT EXECUTE ON salt_alta_postal TO
superpjp, supersre, supersbl,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

