enum FilterType {
  
  day('Dia'),
  week('Semana'),
  month('Mês'),
  year('Ano'),
  type('Tipo'),
  albuns('Álbuns'),
  all('Todos');

  final String label;
  const FilterType(this.label);
}
