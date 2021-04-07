drop procedure get_rutalectura;

CREATE PROCEDURE mi_get_rutalectura(
p_tipo_cliente  char(2),
p_sucursal		char(4),
p_partido       char(3),
p_comuna        char(3),
p_cod_calle     char(6),
altura          char(5))
RETURNING smallint as sector, integer as zona, integer as correlativo_ruta;

DEFINE ret_sector   smallint;
DEFINE ret_zona     integer;
DEFINE ret_correlativo  integer;

DEFINE largo        integer;
DEFINE iAltura      integer;
DEFINE inicio       integer;
DEFINE fin          integer;
DEFINE iParidad     integer;
DEFINE sInicio      char(8);
DEFINE sFin         char(8);
DEFINE iMax1        integer;

    LET largo=length(trim(altura));
    LET iAltura=TO_NUMBER(NVL(altura, 0));
    LET iParidad=MOD(iAltura,2);
    
    IF iAltura < 100 THEN
        LET inicio=0;
        LET fin=99;
    ELSE
        LET iMax1=largo-2;
        LET sInicio=substr(altura,1, iMax1) || '00';
        LET sFin=substr(altura,1, iMax1) || '99';
        LET inicio=TO_NUMBER(sInicio);
        LET fin=TO_NUMBER(sFin);
    END IF;                                                                                       
    
    IF iParidad=0 THEN
        -- VEREDA PAR
        SELECT sector, zona, MAX(correlativo_ruta) + 2 INTO ret_sector, ret_zona, ret_correlativo
        FROM cliente
        WHERE sucursal = p_sucursal
        AND partido = p_partido
        AND comuna = p_comuna
        AND cod_calle = p_cod_calle
        AND to_number(nvl(nro_dir,0)) BETWEEN inicio AND fin
        AND estado_cliente = 0
        AND mod(to_number(nvl(nro_dir,0)), 2)=0
        GROUP BY 1,2;
        
    ELSE
        -- VEREDA IMPAR
        SELECT sector, zona, MAX(correlativo_ruta) + 2 INTO ret_sector, ret_zona, ret_correlativo
        FROM cliente
        WHERE sucursal = p_sucursal
        AND partido = p_partido
        AND comuna = p_comuna
        AND cod_calle = p_cod_calle
        AND to_number(nvl(nro_dir,0)) BETWEEN inicio AND fin
        AND estado_cliente = 0
        AND mod(to_number(nvl(nro_dir,0)), 2)!=0
        GROUP BY 1,2;
        
    END IF;
    
	return ret_sector, ret_zona, ret_correlativo;
	
END PROCEDURE;

GRANT EXECUTE ON mi_get_rutalectura TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
