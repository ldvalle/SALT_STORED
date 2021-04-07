DROP PROCEDURE sfc_verif_clteviejo;

CREATE PROCEDURE sfc_verif_clteviejo(
nroClienteVjo	LIKE cliente.numero_cliente)
RETURNING smallint as codigo, char(100) as descripcion, char(20) as procedimiento;

DEFINE retCodigo smallint;
DEFINE retDescripcion  char(100);
DEFINE retProcedimiento char(20);

DEFINE auxEstado   integer;
DEFINE auxCod   smallint;
DEFINE auxDesc  char(100);
DEFINE auxCodProc   char(1);
DEFINE nrows        integer;

    SET ISOLATION TO DIRTY READ;
    
    SELECT c.estado_cliente, NVL(r.codigo, 'A') INTO auxEstado, auxCodProc
    FROM cliente c, OUTER retcli r
    WHERE c.numero_cliente = nroClienteVjo
    AND r.numero_cliente = c.numero_cliente;

	LET nrows = DBINFO('sqlca.sqlerrd2');
	IF nrows = 0 THEN
		RETURN 1, 'Cliente Antecesor NO Existe MAC.', null;
	END IF;

    IF auxEstado != 0 THEN
        RETURN 2, 'Cliente Antecesor NO Activo en MAC.', null;
    ELIF auxCodProc = 'R' THEN
        RETURN 3, 'Cliente Antecesor con proceso pendiente en MAC.', 'RETCLI';
    ELIF auxCodProc = 'C' THEN
        LET retCodigo = 0;
        LET retDescripcion = 'Cliente Antecesor con proceso pendiente en MAC.';
        LET retProcedimiento = 'MANSER'; 
    ELSE
        LET retCodigo = 0;
        LET retDescripcion = 'Cliente Antecesor sin proceso pendiente en MAC.';
        LET retProcedimiento = NULL; 
    END IF;
    
    RETURN retCodigo, retDescripcion, retProcedimiento;

END PROCEDURE;


GRANT EXECUTE ON sfc_verif_clteviejo TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
