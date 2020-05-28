CREATE PROCEDURE salt_valida_compropago(
nroCliente			like cliente.numero_cliente, 
stsTarifa			like cliente.tarifa, 
stsCliente			like cliente.estado_cliente, 
stsFacturacion	    like cliente.estado_facturacion,
stsCob				like	cliente.estado_cobrabilida, 
sFlag				like tabla.valor_alf,
tipoSuministro		like cliente.tipo_sum)
RETURNING integer, char(100);

DEFINE codSts	int;
DEFINE descSts char(100);
DEFINE iTiene	int;


	-------------------------
	IF TRIM(stscob) = '3' THEN
		LET codSts=1;
		LET descSts= 'Tiene Estado Cobrabilidad JUDICIAL';
		RETURN codSts, descSts;	
	END IF;

	-------------------------
	LET iTiene=0;

	SELECT COUNT(*) INTO iTiene
	FROM cliente c, depgar dg 
	WHERE c.numero_cliente = nroCliente
	AND dg.numero_cliente = nroCliente
	AND NVL(dg.estado_dg, '*') = 'F'
	AND NVL(dg.origen, '*') <> 'F'
	AND dg.estado <> '0';

	IF iTiene > 0 THEN
		LET codSts=1;
		LET descSts= 'Tiene DG facturado y no pagado. Debe pagar primero el DG';
		RETURN codSts, descSts;
	END IF;

	-------------------------
	LET iTiene=0;

	SELECT COUNT(*) INTO iTiene
	FROM entiofi e, cliente c 
	WHERE c.numero_cliente = nroCliente
	AND e.entidad  = c.minist_repart
	AND e.compensa = 'S';

	IF iTiene > 0 THEN
		LET codSts=1;
		LET descSts= 'Cliente Hijo de Padre Compensador';
		RETURN codSts, descSts;
	END IF;

	-------------------------
	IF tipoSuministro = 4 THEN
		LET codSts=1;
		LET descSts= 'El Cliente es Oficial';
		RETURN codSts, descSts;
	END IF;	
	-------------------------
	IF tipoSuministro = 5 THEN
		LET codSts=1;
		LET descSts= 'El Cliente es Consolidador';
		RETURN codSts, descSts;
	END IF;		
	-------------------------
	IF tipoSuministro = 6 AND stsTarifa[1,2]='AP' THEN
		LET iTiene=0;
		
		SELECT COUNT(*) INTO iTiene
		FROM entiofi e, cliente c
		WHERE c.numero_cliente = nroCliente
		AND e.entidad  = c.minist_repart
		AND e.compensa = 'S';
                                                 		
		IF iTiene > 0 THEN
			LET codSts=1;
			LET descSts= 'El Cliente es Consolidador';
			RETURN codSts, descSts;
		END IF;
	END IF;	

	RETURN 0, 'OK';

END PROCEDURE;


GRANT EXECUTE ON salt_valida_compropago TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
