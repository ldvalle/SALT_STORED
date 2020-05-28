CREATE PROCEDURE salt_arma_barra(
sucur_cliente		char(4),
plan					int,
nro_cliente			int,
monto					float,
fecha_fmt			char(6),
nro_comprobante	char(3),
motivo				char(2))
returning char(60), char(1);

DEFINE sBarraAux	char(60);
DEFINE sBarra    	char(60);
DEFINE dv_barra   char(1);
DEFINE largo		int;
DEFINE i				int;
DEFINE totPar		int;
DEFINE totImp		int;

DEFINE sParte1 	char(10);
DEFINE largo1 		int;
DEFINE cParte1 	char(1);
	
DEFINE sParte2		char(10);
DEFINE largo2		int;

	LET sBarraAux = '009'|| sucur_cliente[3, 4] || lpad(plan, 2, '0') || 
			lpad(nro_cliente, 8, '0') ||
			lpad(round((monto * 100),0), 9, '0') || fecha_fmt || '000000' || 
			'0000' || nro_comprobante || motivo;

	LET largo = length(sBarraAux);
	LET totPar = 0;
	LET totImp = 0;
	LET i=1;
	
	FOR i= 1 TO largo
		IF mod(i,2) = 0 THEN
			LET totPar = totPar + to_number(substr(sBarraAux,i,1));
		ELSE
			LET totImp = totImp + to_number(substr(sBarraAux,i, 1));
		END IF;
	END FOR;

	LET sParte1 = trim(to_char((totImp * 3 + totPar)));
	LET largo1 = length(sParte1);
	LET cParte1 = substr(sParte1, largo1, 1);
	
	LET sParte2 = trim(to_char((10 - round(to_number(cParte1),0))));
	LET largo2 = length(sParte2);
	LET dv_barra = substr(sParte2, largo2, 1);
	
	LET sBarra = trim(sBarraAux) || trim(dv_barra);

	return sBarra, dv_barra;
	
END PROCEDURE;

GRANT EXECUTE ON salt_arma_barra TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
