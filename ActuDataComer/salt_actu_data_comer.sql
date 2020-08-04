CREATE PROCEDURE salt_actu_data_comer(
numeroCliente	LIKE cliente.numero_cliente,
nroOrden			int,
Nombre		 	LIKE cliente.nombre,
tipoDoc			LIKE cliente.tip_doc,
nroDoc 			like cliente.nro_doc,
Telefono			LIKE cliente.telefono,
e_mail			char(60))
RETURNING integer as codigo, char(100) as descripcion;

DEFINE codSts	int;
DEFINE descSts char(50);

DEFINE miNroCliente int;
DEFINE miNroOrden   int;
DEFINE miNombre		char(50);
DEFINE miTipoDoc		char(5);
DEFINE miNroDoc		float;
DEFINE miTelefono		char(15);
DEFINE miEmail			char(60);

DEFINE msgError CHAR(50); 
DEFINE error_data_var CHAR(20);
DEFINE error_number, error_issam INT;

DEFINE stsCliente			CHAR(1);
DEFINE stsFacturacion	CHAR(1);
DEFINE tipoFpago			CHAR(1);
DEFINE tipoReparto		CHAR(1);
DEFINE esElectro			CHAR(1);

DEFINE	actu_nombre LIKE cliente.nombre;
DEFINE	actu_tipo_doc LIKE cliente.tip_doc;
DEFINE	actu_nro_doc LIKE cliente.nro_doc;
DEFINE	actu_telefono LIKE cliente.telefono;
DEFINE	actu_rut LIKE cliente.rut;
DEFINE  miCuit varchar(11,0);

	-- registro lockeado
    ON EXCEPTION IN (-107, -144, -113)
    	ROLLBACK WORK;
    	return 1, 'ERR - Tabla mi_cliente lockeada';
    END EXCEPTION;

	-- clave duplicada
    ON EXCEPTION IN (-236, -100)
    	ROLLBACK WORK;
    	return 2, 'ERR - Tabla mi_cliente Clave Duplicada';
    END EXCEPTION;

	-- Error desconocido
{	
    ON EXCEPTION
    	SET error_number, error_issam, error_data_var
		
		LET msgError = 'ERR - ' || error_number || ' ' || error_data_var;
		
    	return 3, msgError;
    END EXCEPTION;
}


	-- Normalizacion de parametros
	IF numeroCliente IS NULL THEN
		return 1, 'ERR - Nro.de cliente con valor nulo';
	END IF;

	LET miNroCliente = numeroCliente;

	IF nroOrden IS NULL THEN
		LET miNroOrden=NULL;
	ELSE
		LET miNroOrden=nroOrden;
	END IF;

	IF TRIM(Nombre)= '' THEN
		LET miNombre = NULL;
	ELSE
		LET miNombre = Nombre;
	END IF;

	IF TRIM(tipoDoc)= '' THEN
		LET miTipoDoc = NULL;
	ELSE
		LET miTipoDoc = tipoDoc;
	END IF;
	
	IF nroDoc IS NULL THEN
		LET miNroDoc = NULL;
	ELSE
		LET miNroDoc = nroDoc;
	END IF;
	
	IF TRIM(Telefono)= '' THEN
		LET miTelefono = NULL;
	ELSE
		LET miTelefono = Telefono;
	END IF;

	IF TRIM(e_mail)= '' THEN
		LET miEmail = NULL;
	ELSE
		LET miEmail = e_mail;
	END IF;
	
	-- Estado gral del cliente
	SELECT c.estado_cliente stsCliente, 
	c.estado_facturacion stsFacturacion,
	c.tipo_fpago tipoFpago,
	c.tipo_reparto tipoReparto,
	DECODE(v.numero_cliente, NULL, 'N', 'S') esElectro,
	c.nombre,
	c.tip_doc, 
	c.nro_doc,
	c.telefono,
	c.rut
	INTO
		stsCliente,
		stsFacturacion,
		tipoFpago,
		tipoReparto,
		esElectro,
		actu_nombre,
		actu_tipo_doc,
		actu_nro_doc,
		actu_telefono,
		actu_rut
	FROM cliente c, OUTER( clientes_vip v, tabla t1)
	WHERE c.numero_cliente = miNroCliente
	AND v.numero_cliente = c.numero_cliente
	AND v.fecha_activacion <= TODAY 
	AND (v.fecha_desactivac IS NULL OR v.fecha_desactivac > TODAY) 
	AND t1.nomtabla = 'SDCLIV' 
	AND t1.codigo = v.motivo 
	AND t1.valor_alf[4] = 'S' 
	AND t1.sucursal = '0000' 
	AND t1.fecha_activacion <= TODAY 
	AND ( t1.fecha_desactivac >= TODAY OR t1.fecha_desactivac IS NULL );

	-- Validaciones x estado
	IF TRIM(esElectro)='S' AND miNombre IS NOT NULL THEN
		RETURN 1, 'Cliente ElectroDependiente - No se puede cambiar nombre';
	END IF;
	
	IF miNombre IS NOT NULL THEN
        IF (TRIM(miNombre) != TRIM(actu_nombre)) OR actu_nombre IS NULL THEN
            --Actualizar nombre 4
            EXECUTE PROCEDURE salt_actu_nombre(miNroCliente, miNroOrden, actu_nombre, miNombre, 4)
                INTO codSts, descSts;
            
            IF codSts != 0 THEN
                RETURN codSts, descSts;
            END IF;
		END IF;
	END IF;
	
	IF TRIM(miTipoDoc)='CUIT' OR TRIM(miTipoDoc)='CUIL' THEN
        IF miNroDoc IS NOT NULL THEN
            --Actualizar CUIT
            LET miCuit = TO_CHAR(ROUND(miNroDoc, 0));
            
            EXECUTE PROCEDURE salt_actu_cuit(miNroCliente, miNroOrden, actu_rut, miCuit, 7)
                INTO codSts, descSts;
            
            IF codSts != 0 THEN
                RETURN codSts, descSts;
            END IF;        
        END IF;
	ELSE
        IF miTipoDoc IS NOT NULL THEN
            IF (SELECT COUNT(*) FROM tabla
                    WHERE nomtabla = 'TIPDOC'
                    AND sucursal = '0000'
                    AND codigo = TRIM(miTipoDoc)
                    AND fecha_activacion <= TODAY
                    AND (fecha_desactivac IS NULL OR  fecha_desactivac > TODAY)) <= 0 THEN
                    
                    LET codSts=1;
                    LET descSts='Tipo de documento invalido.';

                return codSts, descSts;
            END IF;
        
            IF (TRIM(miTipoDoc) != TRIM(actu_tipo_doc)) OR actu_tipo_doc IS NULL THEN
                --Actualizar Tipo Documento 64
                EXECUTE PROCEDURE salt_actu_tip_doc(miNroCliente, miNroOrden, actu_tipo_doc, miTipoDoc, 64)
                    INTO codSts, descSts;
                
                IF codSts != 0 THEN
                    RETURN codSts, descSts;
                END IF;
            END IF;
        END IF;
        
        IF miNroDoc IS NOT NULL THEN
            IF (miNroDoc != actu_nro_doc) OR actu_nro_doc IS NULL THEN
                --Actualizar Nro.de documento 60
                EXECUTE PROCEDURE salt_actu_nro_doc(miNroCliente, miNroOrden, actu_nro_doc, miNroDoc, 60)
                    INTO codSts, descSts;
                
                IF codSts != 0 THEN
                    RETURN codSts, descSts;
                END IF;
            END IF;
        END IF;
    END IF;
    
	IF miTelefono IS NOT NULL THEN
        IF (TRIM(miTelefono) != TRIM(actu_telefono)) OR actu_telefono IS NULL THEN
            -- Actualizar Telefono ppal 89
            EXECUTE PROCEDURE salt_actu_telefono(miNroCliente, miNroOrden, actu_telefono, miTelefono, 89)
                INTO codSts, descSts;
            
            IF codSts != 0 THEN
                RETURN codSts, descSts;
            END IF;
		END IF;
	END IF;

	IF miEmail IS NOT NULL THEN
		-- No tiene Codigo Modif Asociado
		EXECUTE PROCEDURE salt_actu_email(miNroCliente, miNroOrden, miEmail)
			INTO codSts, descSts;
		
		IF codSts != 0 THEN
			RETURN codSts, descSts;
		END IF;		
	END IF;
	
    IF codSts != 0 THEN
        RETURN codSts, descSts;
    END IF;	
	
	RETURN 0, 'OK';

END PROCEDURE;


GRANT EXECUTE ON salt_actu_data_comer TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;

