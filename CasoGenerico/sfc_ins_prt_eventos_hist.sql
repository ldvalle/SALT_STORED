DROP PROCEDURE sfc_ins_prt_eventos_hist;

CREATE PROCEDURE sfc_ins_prt_eventos_hist(
serie_precinto  like prt_precintos.serie, 
nro_precinto    like prt_precintos.numero_precinto, 
nroMedidor      like prt_precintos.numero_medidor,
marcaMedidor    like prt_precintos.marca,
modeloMedidor   like prt_precintos.modelo, 
corrEvento      like prt_precintos.corr_evento, 
codEvento       like prt_eventos_hist.evento,
valEvento       like prt_eventos_hist.valor_evento,
estado          like prt_eventos_hist.estado, 
sucursal        like prt_eventos_hist.sucursal, 
funcion         like prt_eventos_hist.funcion)
RETURNING smallint as codigo, char(100) as descripcion;

DEFINE sql_err              INTEGER;
DEFINE isam_err             INTEGER;
DEFINE error_info           CHAR(100);

    ON EXCEPTION SET sql_err, isam_err, error_info
        RETURN 1, 'sfcInsPrtEventosHist. sqlErr '  || to_char(sql_err) || ' isamErr ' || to_char(isam_err) || ' ' || error_info;
    END EXCEPTION;

    INSERT INTO prt_eventos_hist ( 
      serie, 
      numero_precinto, 
      corr_evento, 
      evento, 
      valor_evento, 
      fecha, 
      aplicacion, 
      numero_medidor, 
      marca, 
      modelo, 
      rol, 
      dir_ip, 
      estado,
      sucursal,
      funcion
    ) VALUES (
      serie_precinto,
      nro_precinto,
      corrEvento,
      codEvento,
      valEvento,
      CURRENT,
      'INCORPORACION',
      nroMedidor,
      marcaMedidor,
      modeloMedidor,
      'SALESFORCE', 
      '100.25.0.15', 
      estado,
      sucursal,
      funcion);

    RETURN 0, 'OK';
END PROCEDURE;


GRANT EXECUTE ON sfc_ins_prt_eventos_hist TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1, fuse,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
