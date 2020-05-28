CREATE PROCEDURE salt_get_secuen(
clave						like secuen.codigo, 
sucur_get				like secuen.sucursal)
RETURNING integer, char(100), char(3);

DEFINE codSts	int;
DEFINE descSts char(100);
DEFINE iTiene	int;
DEFINE iValor  float;
DEFINE sValor  char(3);

	-- registro lockeado
   ON EXCEPTION IN (-107, -144, -113)
		ROLLBACK WORK;
    	return 1, 'ERR - SECUEN lockeada', '';
   END EXCEPTION;

	SELECT 
		CASE
			WHEN valor IS NULL THEN 0
			WHEN valor >= 999 THEN 0
			ELSE ROUND(valor, 0)
		END	
	INTO 
		iValor 
	FROM secuen
	WHERE codigo = clave
	AND sucursal = sucur_get;

	UPDATE secuen SET
		valor = valor +1
	WHERE codigo = clave
	AND sucursal = sucur_get;	

	LET sValor = LPAD(round(iValor,0), 3, '0');

	RETURN 0, 'OK', sValor;

END PROCEDURE;


GRANT EXECUTE ON salt_get_secuen TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
