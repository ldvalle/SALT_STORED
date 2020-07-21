CREATE PROCEDURE salt_actu_email(
numeroCliente	LIKE cliente.numero_cliente,
nroOrden			int,
email	 			char(60))
RETURNING integer, char(100);

DEFINE codRetorno	integer;
DEFINE descRetorno char(100);

	-- registro lockeado
    ON EXCEPTION IN (-107, -144, -113)
    	ROLLBACK WORK;
    	return 1, 'ERR - Tabla CLIENTE lockeada';
    END EXCEPTION;

    UPDATE cliente_mail set
    rol_desactivac = 'SALESFORCE',
    fecha_desactivac = TODAY
    WHERE numero_cliente = numeroCliente 
    AND fecha_desactivac IS NULL;
    
    
	INSERT INTO cliente_mail (
	numero_cliente, email, ppal_mail, fecha_activacion, rol_activacion
	)VALUES(numeroCliente, TRIM(email), 'S', TODAY, 'SALESFORCE');
		
	return 0, 'OK';

END PROCEDURE;

GRANT EXECUTE ON salt_actu_email TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

