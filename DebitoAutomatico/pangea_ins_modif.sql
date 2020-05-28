DROP PROCEDURE pangea_ins_modif;

CREATE PROCEDURE pangea_ins_modif(NumeroCliente LIKE modif.numero_cliente, TipoOrden LIKE modif.tipo_orden, NumeroOrden LIKE modif.numero_orden, Ficha LIKE modif.ficha, TipoCliente LIKE modif.tipo_cliente, CodigoModif LIKE modif.codigo_modif, DatoAnterior LIKE modif.dato_anterior, DatoNuevo LIKE modif.dato_nuevo, Procedimiento LIKE modif.proced, DirIP LIKE modif.dir_ip)
    RETURNING SMALLINT AS codigo, CHAR(100) AS descripcion;

--************************************************************
--
-- PROPOSITO: Inserta un regitro de modificación
--
-- PARAMETROS:
--      NumeroCliente
--      TipoOrden
--      NumeroOrden
--      Ficha
--      TipoCliente
--      CodigoModif
--      DatoAnterior
--      DatoNuevo
--      Procedimiento
--      DirIP
--
-- VALORES DE RETORNO:
--      SMALLINT : Cod.resultado: 0 -> OK
--                                1 -> Error
--      CHAR(100): Descripción resultado
--
-- AUTOR: Pablo Privitera
-- FECHA DE CREACION: 08/2019
--
--************************************************************

    DEFINE sql_err              INT;
    DEFINE isam_err             INT;
    DEFINE error_info           CHAR(100);

    ON EXCEPTION SET sql_err, isam_err, error_info
        RETURN 1, error_info;
        --RAISE EXCEPTION sql_err, isam_err, error_info;
    END EXCEPTION;

    INSERT INTO modif (
                numero_cliente,
                tipo_orden,
                numero_orden,
                ficha,
                fecha_modif,
                tipo_cliente,
                codigo_modif,
                dato_anterior,
                dato_nuevo,
                proced,
                dir_ip
            ) VALUES (
                NumeroCliente,
                TipoOrden,
                NumeroOrden,
                Ficha,
                CURRENT,
                TipoCliente,
                CodigoModif,
                DatoAnterior,
                DatoNuevo,
                Procedimiento,
                DirIP);

    RETURN 0, "OK" ;
END PROCEDURE;

--EXECUTE pangea_ins_modif
GRANT EXECUTE ON pangea_ins_modif TO
superpjp, supersre, supersbl,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
