CREATE PROCEDURE debito_dumi(NroCliente INTEGER, Solicitud CHAR(1), TipoCuenta CHAR(2), CodBanco CHAR(4), CBU CHAR(22), ClaseTarjeta CHAR(4), NroTarjeta CHAR(20))
    RETURNING INTEGER AS codigo, CHAR(100) AS descripcion;

	RETURN 0, 'OK';

END PROCEDURE;

GRANT EXECUTE ON debito_dumi TO
superpjp, supersre, supersbl,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
