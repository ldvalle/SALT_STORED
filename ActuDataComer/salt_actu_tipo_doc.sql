CREATE PROCEDURE salt_actu_tip_doc(
numeroCliente	LIKE cliente.numero_cliente,
nroOrden				int,
tipo_doc_anterior 	LIKE cliente.tip_doc,
tipo_doc_nuevo			LIKE cliente.tip_doc,
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
	tip_doc = TRIM(tipo_doc_nuevo)
	WHERE numero_cliente = numeroCliente;
	
	EXECUTE PROCEDURE salt_graba_modif(numeroCliente, cod_modif, 'SALESFORCE', 'SALT-T1', tipo_doc_anterior, tipo_doc_nuevo)
		INTO codRetorno, descRetorno;
	
	return codRetorno, descRetorno;

END PROCEDURE;

GRANT EXECUTE ON salt_actu_tip_doc TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
