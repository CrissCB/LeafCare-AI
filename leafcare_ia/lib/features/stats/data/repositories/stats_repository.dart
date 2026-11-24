import 'package:leafcare_ia/features/stats/data/datasources/stats_datasource.dart';
import 'package:leafcare_ia/features/stats/data/models/stats_summary_model.dart';

class StatsRepository {
  const StatsRepository({required this.datasource});

  final StatsDatasource datasource;

  Future<StatsSummaryModel> getStatsSummary() => datasource.fetchStatsSummary();
}
