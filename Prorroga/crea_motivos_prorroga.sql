begin work;

insert into corplazo_motivo (codigo, descripcion, fecha_activac
)values('11', 'Desición Comercial', today);

insert into corplazo_tope (motivo, frecuencia, tope_dias
)values('11', 'M', 30);

insert into corplazo_tope (motivo, frecuencia, tope_dias
)values('11', 'B', 30);

commit work;
