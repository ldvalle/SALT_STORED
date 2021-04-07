DROP PROCEDURE sfc_contrata_alta_ct;

CREATE PROCEDURE sfc_contrata_alta_ct(
nroClienteNvo	LIKE cliente.numero_cliente,
nroClienteVjo	LIKE cliente.numero_cliente,
nroSolicitud    integer,
nroMensaje      integer
)
RETURNING smallint as codigo, char(100) as descripcion;

DEFINE retCodigo smallint;
DEFINE retDescripcion  char(100);
DEFINE retNroSolicitud  integer;
DEFINE retNroMensaje    integer;
DEFINE retNroOrden      integer;

DEFINE auxCod   smallint;
DEFINE auxDesc  char(50);
DEFINE proc_pend    char(20);

    -- Verificar Cliente viejo y procedimientos pendientes
    EXECUTE PROCEDURE sfc_verif_clteviejo(nroClienteVjo) INTO auxCod, auxDesc, proc_pend;
    
    IF auxCod != 0 THEN
        RETURN auxCod, auxDesc;
    END IF; 
    
    -- Mueve Clientes  
    EXECUTE PROCEDURE sfc_mover_clientes(nroClienteVjo, nroClienteNvo, nroSolicitud) INTO auxCod, auxDesc;

    IF auxCod != 0 THEN
        RETURN auxCod, auxDesc;
    END IF; 

    -- Mueve Medidores
    EXECUTE PROCEDURE sfc_mover_medidor(nroClienteVjo, nroClienteNvo, nroSolicitud) INTO auxCod, auxDesc;

    IF auxCod != 0 THEN
        RETURN auxCod, auxDesc;
    END IF; 

	RETURN 0, 'OK';

END PROCEDURE;


GRANT EXECUTE ON sfc_contrata_alta_ct TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;


