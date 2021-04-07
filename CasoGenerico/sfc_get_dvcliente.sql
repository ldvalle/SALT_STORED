DROP PROCEDURE sfc_get_dvcliente;

CREATE PROCEDURE sfc_get_dvcliente(
nroCliente	LIKE cliente.numero_cliente)
RETURNING char(1) as dv;

DEFINE sNroCliente char(8);
DEFINE nvo_dv char(1);
DEFINE rut char(11);
DEFINE sFactor char(9);
DEFINE suma integer;
DEFINE largo integer;
DEFINE j integer;
DEFINE i integer;
DEFINE resu integer;

    LET rut='1234567890K';
    LET sFactor= '234567234';
    LET suma=0;
    LET j=1;
    LET sNroCliente=TRIM(TO_CHAR(nroCliente));
    LET largo=LENGTH(sNroCliente);

    FOR i=largo TO 1 STEP -1
        LET suma=suma + TO_NUMBER(SUBSTR(sNroCliente, i, 1)) * TO_NUMBER(SUBSTR(sFactor, j, 1));
        LET j=j+1;
    END FOR;
    
    LET resu=11-(suma - trunc(suma/11)*11);
    LET nvo_dv=SUBSTR(rut, resu, 1);
    
    RETURN nvo_dv;
END PROCEDURE;

GRANT EXECUTE ON sfc_get_dvcliente TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
