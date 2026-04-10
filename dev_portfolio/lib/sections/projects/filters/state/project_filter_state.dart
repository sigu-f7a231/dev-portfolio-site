class ProjectFilterState {
  final Map<String, List<String>> selectedFilters;

  ProjectFilterState({required this.selectedFilters});

  factory ProjectFilterState.initial() {
    return ProjectFilterState(
      selectedFilters: {
        'serverOS': [],
        'db': [],
        'tools': [],
        'backendFrameworks': [],
        'frontendFrameworks': [],
        'uiFrameworks': [],
        'testingFrameworks': [],
        'cloudPlatforms': [],
        'awsServices': [],
        'azureServices': [],
        'gcpServices': [],
        'container': [],
        'containerOrchestration': [],
        'aiServices': [],
        'skills': [],
        'workflow': [],
      },
    );
  }
}