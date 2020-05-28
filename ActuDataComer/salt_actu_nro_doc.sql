CREATE PROCEDURE salt_actu_nro_doc(
numeroCliente	LIKE cliente.numero_cliente,
nroOrden				int,
nro_doc_anterior 	LIKE cliente.nro_doc,
nro_doc_nuevo		LIKE cliente.nro_doc,
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
	nro_doc = nro_doc_nuevo
	WHERE numero_cliente = numeroCliente;
	
	EXECUTE PROCEDURE salt_graba_modif(numeroCliente, cod_modif, 'SALESFORCE', 'SALT-T1', to_char(nro_doc_anterior), to_char(nro_doc_nuevo))
		INTO codRetorno, descRetorno;

	return codRetorno, descRetorno;

END PROCEDURE;

GRANT EXECUTE ON salt_actu_nro_doc TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
