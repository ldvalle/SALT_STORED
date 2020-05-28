CREATE PROCEDURE sp_setmicliente(
numeroCliente	LIKE mi_cliente.numero_cliente,
nroOrden			LIKE mi_cliente.nro_orden,
Nombre		 	LIKE mi_cliente.nombre,
tipoDoc			LIKE mi_cliente.tipo_doc,
nroDoc 			LIKE mi_cliente.nro_doc,
Telefono			LIKE mi_cliente.telefono)
RETURNING integer, char(50);

DEFINE miNroCliente int;
DEFINE miNroOrden   int;
DEFINE miNombre		char(50);
DEFINE miTipoDoc		char(5);
DEFINE miNroDoc		int;
DEFINE miTelefono		char(15);

DEFINE msgError CHAR(50); 
DEFINE error_data_var CHAR(20);
DEFINE error_number, error_issam INT;

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
    	
	
    INSERT INTO mi_cliente (
    numero_cliente,
    nro_orden,
    nombre,
    tipo_doc,
    nro_doc,
    telefono
    )VALUES(
    miNroCliente,
    miNroOrden,
    miNombre,
    miTipoDoc,
    miNroDoc,
    miTelefono);
			
	
	RETURN 0, 'OK';

END PROCEDURE;

