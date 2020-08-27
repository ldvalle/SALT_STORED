CREATE PROCEDURE app_saldos_exi_noexi(numeroCliente	LIKE cliente.numero_cliente)
RETURNING float as saldo_exigible, float as saldo_no_exigible;

DEFINE saldoTotal float;
DEFINE montoSaldoExigible float;
DEFINE montoSaldoNoExigible float;
DEFINE saldoFinal float;

DEFINE nrows int;

DEFINE c_estado_cliente like cliente.estado_cliente;
DEFINE c_saldo_actual like cliente.saldo_actual;
DEFINE c_saldo_int_acum like cliente.saldo_int_acum;
DEFINE c_saldo_imp_no_suj_i like cliente.saldo_imp_no_suj_i;
DEFINE c_saldo_imp_suj_int like cliente.saldo_imp_suj_int;
DEFINE c_valor_anticipo like cliente.valor_anticipo;
DEFINE h_fecha_facturacion like hisfac.fecha_facturacion;
DEFINE h_fecha_vencimiento1 like hisfac.fecha_vencimiento1;
DEFINE h_tipo_fpago like hisfac.tipo_fpago;
DEFINE h_corr_facturacion like hisfac.corr_facturacion;
DEFINE h_total_facturado like hisfac.total_facturado;
DEFINE h_suma_convenio like hisfac.suma_convenio;
DEFINE r_suma_notas_noexigible float;
DEFINE r_suma_cnr_noexigible float;
DEFINE r_dg_noexigible float;
DEFINE r_tasa_noexigible float;
DEFINE r_transfer_noexigible float;

    LET saldoTotal=0;
    LET montoSaldoExigible = 0;
    LET montoSaldoNoExigible = 0;
    LET saldoFinal = 0;
    LET r_suma_notas_noexigible = 0;
    LET r_suma_cnr_noexigible = 0;
    LET r_dg_noexigible = 0;
    LET r_tasa_noexigible = 0;
    LET r_transfer_noexigible = 0;
    
    SELECT c.estado_cliente,
    c.saldo_actual,
    c.saldo_int_acum,
    c.saldo_imp_no_suj_i,
    c.saldo_imp_suj_int,
    c.valor_anticipo,
    h.fecha_facturacion,
    h.fecha_vencimiento1,
    h.tipo_fpago,
    h.corr_facturacion,
    h.total_facturado,
    h.suma_convenio
    INTO
        c_estado_cliente,
        c_saldo_actual,
        c_saldo_int_acum,
        c_saldo_imp_no_suj_i,
        c_saldo_imp_suj_int,
        c_valor_anticipo,
        h_fecha_facturacion,
        h_fecha_vencimiento1,
        h_tipo_fpago,
        h_corr_facturacion,
        h_total_facturado,
        h_suma_convenio
    FROM cliente c, hisfac h
    WHERE c.numero_cliente =  numeroCliente
    AND h.numero_cliente = c.numero_cliente
    AND h.corr_facturacion = c.corr_facturacion;
    
    LET nrows = DBINFO('sqlca.sqlerrd2');
    
    IF nrows = 0 THEN
        RETURN montoSaldoExigible, montoSaldoNoExigible;
    END IF;
    
    LET saldoTotal = c_saldo_actual + c_saldo_int_acum + c_saldo_imp_no_suj_i + c_saldo_imp_suj_int - c_valor_anticipo;
    
    -- Si no esta activo lo liquidamos aca
    IF c_estado_cliente != 0 THEN
        LET montoSaldoExigible = saldoTotal;
        LET montoSaldoNoExigible = 0;
        
        RETURN montoSaldoExigible, montoSaldoNoExigible;
    END IF;

    -- Sumatoria de Notas de Debito NO vencidas
    SELECT NVL(SUM(total_refacturado),0) INTO r_suma_notas_noexigible
    FROM refac 
    WHERE numero_cliente = numeroCliente
    AND tipo_nota = 'D' 
    AND ( fecha_vencimiento IS NULL OR fecha_vencimiento >= TODAY);
 
    -- Sumatoria Facturas CNRs No vencidas
    SELECT NVL(SUM(total_facturado), 0) INTO r_suma_cnr_noexigible
    FROM cnr_factura
    WHERE numero_cliente = numeroCliente
    AND fecha_vencimiento >= TODAY
    AND cod_estado <> 'A'
    AND tipo_docto <> '19';
    
    -- Deposito en Garantia
    SELECT valor_deuda INTO r_dg_noexigible
    FROM depgar
    WHERE numero_cliente = numeroCliente
    AND origen = 'C'
    AND estado IN ('1','2')
    AND estado_dg IN ('C','F');
    
    LET nrows = DBINFO('sqlca.sqlerrd2');
    IF nrows = 0 THEN
        LET r_dg_noexigible = 0;
    END IF;
    
    -- Saldo Tasa
    SELECT saldo_tasa INTO r_tasa_noexigible
    FROM cliente_tasa
    WHERE numero_cliente = numeroCliente;

    LET nrows = DBINFO('sqlca.sqlerrd2');
    IF nrows = 0 THEN
        LET r_tasa_noexigible = 0;
    END IF;
    
    -- Transferencia
    SELECT NVL(SUM(saldo_actual_trans + int_acum_trans + imp_no_suj_i_trans + imp_suj_i_trans - valor_ant_trans), 0)
    INTO r_transfer_noexigible
    FROM transferencia
    WHERE cuenta_destino = numeroCliente
    AND (fecha_vencimiento IS NULL OR fecha_vencimiento >= TODAY);

    -- Calculos
    LET saldoFinal = saldoTotal - r_suma_notas_noexigible - r_suma_cnr_noexigible - r_dg_noexigible - r_tasa_noexigible - r_transfer_noexigible;
    
    IF h_fecha_vencimiento1 < TODAY THEN
        IF saldoFinal > 0.001 THEN
            LET montoSaldoExigible = saldoFinal;
        ELSE
            LET montoSaldoExigible = 0;
        END IF;
    ELSE
        IF saldoFinal > 0.001 THEN
            IF (h_total_facturado + h_suma_convenio) < 0.001 THEN
                LET montoSaldoExigible = saldoFinal;
            ELSE
                LET montoSaldoExigible = saldoFinal - h_total_facturado - h_suma_convenio;
                IF montoSaldoExigible < 0.001 THEN
                    LET montoSaldoExigible = 0;
                END IF;
            END IF;
        ELSE
            LET montoSaldoExigible = 0;
        END IF;
    END IF;
    
    LET montoSaldoNoExigible = saldoTotal - montoSaldoExigible;
    
    RETURN montoSaldoExigible, montoSaldoNoExigible;

END PROCEDURE;


GRANT EXECUTE ON app_saldos_exi_noexi TO
superpjp, supersre, supersbl, supersc, corbacho,
guardt1,
ctousu, batchsyn, procbatc, "UCENTRO", "OVIRTUAL",
pjp, sreyes, sbl, ssalve, gtricoci,
pablop, aarrien, vdiaz, ldvalle, vaz;
