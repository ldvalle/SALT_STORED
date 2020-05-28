CREATE PROCEDURE salt_graba_modif(
numeroCliente		LIKE cliente.numero_cliente, 
cod_modif			LIKE modif.codigo_modif, 
rol_modif			LIKE modif.ficha,
procedimiento		LIKE modif.proced,
nombre_anterior	LIKE modif.dato_anterior,
nombre_nuevo		LIKE modif.dato_nuevo)
RETURNING integer, char(100);

DEFINE codRetorno	integer;
DEFINE descRetorno char(100);

	-- registro lockeado
   ON EXCEPTION IN (-107, -144, -113)
   	ROLLBACK WORK;
   	return 1, 'ERR - Tabla MODIF lockeada';
   END EXCEPTION;

	INSERT INTO modif (
		numero_cliente,
		tipo_orden, 
		ficha,
		fecha_modif,
		tipo_cliente,
		codigo_modif,
		dato_anterior,
		dato_nuevo,
		proced,
		dir_ip
	)VALUES(
		numeroCliente,
		'M',
		trim(rol_modif),
		CURRENT,
		'A',
		cod_modif,
		trim(nombre_anterior),
		trim(nombre_nuevo),
		trim(procedimiento),
		'190.9.120.1');
	
	return 0, 'OK';

END PROCEDURE;

GRANT EXECUTE ON salt_graba_modif TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;


