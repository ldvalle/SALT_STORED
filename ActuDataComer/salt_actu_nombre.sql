CREATE PROCEDURE salt_actu_nombre(
numeroCliente	LIKE cliente.numero_cliente,
nroOrden				int,
nombre_anterior 	LIKE cliente.nombre,
nombre_nuevo		LIKE cliente.nombre,
cod_modif			int)
RETURNING integer, char(100);

DEFINE codRetorno	integer;
DEFINE descRetorno char(100);

	-- registro lockeado
    ON EXCEPTION IN (-107, -144, -113)
    	ROLLBACK WORK;
    	return 1, 'ERR - Tabla CLIENTE lockeada';
    END EXCEPTION;

	UPDATE cliente SET
	nombre = TRIM(nombre_nuevo)
	WHERE numero_cliente = numeroCliente;
	
	EXECUTE PROCEDURE salt_graba_modif(numeroCliente, cod_modif, 'SALESFORCE', 'SALT-T1', nombre_anterior, nombre_nuevo)
		INTO codRetorno, descRetorno;
	
	return codRetorno, descRetorno;

END PROCEDURE;

GRANT EXECUTE ON salt_actu_nombre TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
