CREATE PROCEDURE salt_actu_telefono(
numeroCliente	LIKE cliente.numero_cliente,
nroOrden				int,
telefono_anterior 	LIKE cliente.telefono,
telefono_nuevo		LIKE cliente.telefono,
cod_modif			int)
RETURNING integer, char(100);

DEFINE codRetorno	integer;
DEFINE descRetorno char(100);
DEFINE iNroTelefono integer;

	-- registro lockeado
    ON EXCEPTION IN (-107, -144, -113)
    	ROLLBACK WORK;
    	return 1, 'ERROR DE LOCKEO - no se pudo actualizar telefono';
    END EXCEPTION;

	UPDATE cliente SET
	telefono = TRIM(telefono_nuevo)
	WHERE numero_cliente = numeroCliente;
	
	EXECUTE PROCEDURE salt_graba_modif(numeroCliente, cod_modif, 'SALESFORCE', 'SALT-T1', telefono_anterior, telefono_nuevo)
		INTO codRetorno, descRetorno;
	
	IF codRetorno != 0 THEN
        return codRetorno, descRetorno;
	END IF;
	
    UPDATE telefono SET
    ppal_te = ''
    WHERE cliente = numeroCliente
    AND ppal_te = 'P';
	
	LET iNroTelefono = telefono_nuevo * 1;
	
	INSERT INTO telefono (cliente, tipo_cliente, tipo_te, cod_area_te, numero_te, ppal_te)
    VALUES (numeroCliente, 'C', 'FS', '011', iNroTelefono, 'P');
	
	return 0, 'OK';

END PROCEDURE;

GRANT EXECUTE ON salt_actu_telefono TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

