CREATE PROCEDURE salt_get_nro_logcomprob(
miNroCliente			like cliente.numero_cliente,
motivo					like log_comprob.tipo_comprob,
clave					like secuen.codigo, 
sucur_emi				like secuen.sucursal)
RETURNING integer, char(100), char(3);

DEFINE codSts	int;
DEFINE descSts char(100);
DEFINE nroComprobante char(3);
DEFINE iValor	int;
DEFINE iCantVeces	int;

	SET ISOLATION TO DIRTY READ;
	
	EXECUTE PROCEDURE salt_get_secuen(clave, sucur_emi) INTO codSts, descSts, nroComprobante;
	
	IF codSts != 0 THEN
		RETURN codSts, descSts, '';
	END IF;

	LET iValor = 0;
	LET iCantVeces=0;
	
	SELECT COUNT(*) INTO iValor FROM log_comprob
	WHERE numero_cliente = miNroCliente
	AND tipo_comprob = motivo
	AND nro_comprob = nroComprobante;

	WHILE (iValor > 0 AND iCantVeces < 10)
		-- Sacar el nro.de comprobante
		EXECUTE PROCEDURE salt_get_secuen(clave, sucur_emi) INTO codSts, descSts, nroComprobante;
		
		IF codSts != 0 THEN
			RETURN codSts, descSts, '';
		END IF;
		
		SELECT COUNT(*) INTO iValor FROM log_comprob
		WHERE numero_cliente = miNroCliente
		AND tipo_comprob = motivo
		AND nro_comprob = nroComprobante;		
		
		LET iCantVeces = iCantVeces + 1;
	END WHILE;

	IF codSts != 0 THEN
		RETURN 1, 'No se pudo obtener nro.de comprobante', '';
	END IF;	

	RETURN 0, 'OK', nroComprobante;
END PROCEDURE;

GRANT EXECUTE ON salt_get_nro_logcomprob TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

