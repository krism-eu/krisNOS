cmake_minimum_required(VERSION 3.22)
project(krisNCC VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
include(GNUInstallDirs)

find_package(Qt6 6.7 REQUIRED COMPONENTS Core Gui Qml Quick)
find_package(KF6Kirigami REQUIRED)
qt_standard_project_setup(REQUIRES 6.7)

qt_add_executable(krisNCC
    src/main.cpp
    src/KrisNccBackend.cpp
    src/KrisNccBackend.h
    src/KrisDesktopBackend.cpp
    src/KrisDesktopBackend.h
    src/KrisPackageBackend.cpp
    src/KrisPackageBackend.h
)

set_source_files_properties(qml/components/UiMetrics.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)
set(KRISNCC_QML_FILES
    qml/components/UiMetrics.qml
    qml/Main.qml
    qml/modules/DashboardModule.qml
    qml/modules/SystemModule.qml
    qml/modules/SoftwareModule.qml
    qml/modules/ConfigurationModule.qml
    qml/modules/RecoveryModule.qml
    qml/modules/CleanupModule.qml
    qml/modules/ToolsModule.qml
)
foreach(qml_file IN LISTS KRISNCC_QML_FILES)
    get_filename_component(qml_name "${qml_file}" NAME)
    set_source_files_properties("${qml_file}" PROPERTIES QT_RESOURCE_ALIAS "${qml_name}")
endforeach()

qt_add_qml_module(krisNCC
    URI org.krisncc
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    QML_FILES ${KRISNCC_QML_FILES}
)

target_link_libraries(krisNCC PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick KF6::Kirigami
)

target_compile_definitions(krisNCC PRIVATE KRISNCC_VERSION="${PROJECT_VERSION}")
install(TARGETS krisNCC RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES org.krisncc.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
