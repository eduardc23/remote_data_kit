class PaginatedResponse<T> {
  final List<T> items;
  final bool hasNextPage;
  final int? currentPage;
  final int? totalPages;

  const PaginatedResponse({
    required this.items,
    required this.hasNextPage,
    this.currentPage,
    this.totalPages,
  });
}
