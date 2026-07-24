# Task 1 Review Package

## Status
 M Learning/Learning.xcodeproj/project.pbxproj
 M Learning/Learning/LearningApp.swift
?? Learning/Learning.xcodeproj/xcshareddata/xcschemes/Learning.xcscheme
?? Learning/Learning/MainPage.swift
?? Learning/LearningTests/NavigationShellTests.swift

## Tracked Diff Stat
 Learning/Learning.xcodeproj/project.pbxproj | 133 ++++++++++++++++++++++++++++
 Learning/Learning/LearningApp.swift         |   6 +-
 2 files changed, 138 insertions(+), 1 deletion(-)

## Tracked Diff
diff --git a/Learning/Learning.xcodeproj/project.pbxproj b/Learning/Learning.xcodeproj/project.pbxproj
index cfb8924..c5783f5 100644
--- a/Learning/Learning.xcodeproj/project.pbxproj
+++ b/Learning/Learning.xcodeproj/project.pbxproj
@@ -1,53 +1,78 @@
 // !$*UTF8*$!
 {
 	archiveVersion = 1;
 	classes = {
 	};
 	objectVersion = 77;
 	objects = {
 
+/* Begin PBXContainerItemProxy section */
+		E6A0A209D5F14B3F8A2C1001 /* PBXContainerItemProxy */ = {
+			isa = PBXContainerItemProxy;
+			containerPortal = C79E0CBF300DC8DB00B2AB85 /* Project object */;
+			proxyType = 1;
+			remoteGlobalIDString = C79E0CC6300DC8DB00B2AB85;
+			remoteInfo = Learning;
+		};
+/* End PBXContainerItemProxy section */
+
 /* Begin PBXFileReference section */
 		C79E0CC7300DC8DB00B2AB85 /* Learning.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Learning.app; sourceTree = BUILT_PRODUCTS_DIR; };
+		E6A0A201D5F14B3F8A2C1001 /* LearningTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = LearningTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
 /* End PBXFileReference section */
 
 /* Begin PBXFileSystemSynchronizedRootGroup section */
 		C79E0CC9300DC8DB00B2AB85 /* Learning */ = {
 			isa = PBXFileSystemSynchronizedRootGroup;
 			path = Learning;
 			sourceTree = "<group>";
 		};
+		E6A0A202D5F14B3F8A2C1001 /* LearningTests */ = {
+			isa = PBXFileSystemSynchronizedRootGroup;
+			path = LearningTests;
+			sourceTree = "<group>";
+		};
 /* End PBXFileSystemSynchronizedRootGroup section */
 
 /* Begin PBXFrameworksBuildPhase section */
 		C79E0CC4300DC8DB00B2AB85 /* Frameworks */ = {
 			isa = PBXFrameworksBuildPhase;
 			buildActionMask = 2147483647;
 			files = (
 			);
 			runOnlyForDeploymentPostprocessing = 0;
 		};
+		E6A0A205D5F14B3F8A2C1001 /* Frameworks */ = {
+			isa = PBXFrameworksBuildPhase;
+			buildActionMask = 2147483647;
+			files = (
+			);
+			runOnlyForDeploymentPostprocessing = 0;
+		};
 /* End PBXFrameworksBuildPhase section */
 
 /* Begin PBXGroup section */
 		C79E0CBE300DC8DB00B2AB85 = {
 			isa = PBXGroup;
 			children = (
 				C79E0CC9300DC8DB00B2AB85 /* Learning */,
+				E6A0A202D5F14B3F8A2C1001 /* LearningTests */,
 				C79E0CC8300DC8DB00B2AB85 /* Products */,
 			);
 			sourceTree = "<group>";
 		};
 		C79E0CC8300DC8DB00B2AB85 /* Products */ = {
 			isa = PBXGroup;
 			children = (
 				C79E0CC7300DC8DB00B2AB85 /* Learning.app */,
+				E6A0A201D5F14B3F8A2C1001 /* LearningTests.xctest */,
 			);
 			name = Products;
 			sourceTree = "<group>";
 		};
 /* End PBXGroup section */
 
 /* Begin PBXNativeTarget section */
 		C79E0CC6300DC8DB00B2AB85 /* Learning */ = {
 			isa = PBXNativeTarget;
 			buildConfigurationList = C79E0CD2300DC8DD00B2AB85 /* Build configuration list for PBXNativeTarget "Learning" */;
@@ -63,74 +88,124 @@
 			fileSystemSynchronizedGroups = (
 				C79E0CC9300DC8DB00B2AB85 /* Learning */,
 			);
 			name = Learning;
 			packageProductDependencies = (
 			);
 			productName = Learning;
 			productReference = C79E0CC7300DC8DB00B2AB85 /* Learning.app */;
 			productType = "com.apple.product-type.application";
 		};
+		E6A0A203D5F14B3F8A2C1001 /* LearningTests */ = {
+			isa = PBXNativeTarget;
+			buildConfigurationList = E6A0A20DD5F14B3F8A2C1001 /* Build configuration list for PBXNativeTarget "LearningTests" */;
+			buildPhases = (
+				E6A0A204D5F14B3F8A2C1001 /* Sources */,
+				E6A0A205D5F14B3F8A2C1001 /* Frameworks */,
+				E6A0A206D5F14B3F8A2C1001 /* Resources */,
+			);
+			buildRules = (
+			);
+			dependencies = (
+				E6A0A20AD5F14B3F8A2C1001 /* PBXTargetDependency */,
+			);
+			fileSystemSynchronizedGroups = (
+				E6A0A202D5F14B3F8A2C1001 /* LearningTests */,
+			);
+			name = LearningTests;
+			packageProductDependencies = (
+			);
+			productName = LearningTests;
+			productReference = E6A0A201D5F14B3F8A2C1001 /* LearningTests.xctest */;
+			productType = "com.apple.product-type.bundle.unit-test";
+		};
 /* End PBXNativeTarget section */
 
 /* Begin PBXProject section */
 		C79E0CBF300DC8DB00B2AB85 /* Project object */ = {
 			isa = PBXProject;
 			attributes = {
 				BuildIndependentTargetsInParallel = 1;
 				LastSwiftUpdateCheck = 2660;
 				LastUpgradeCheck = 2660;
 				TargetAttributes = {
 					C79E0CC6300DC8DB00B2AB85 = {
 						CreatedOnToolsVersion = 26.6;
 					};
+					E6A0A203D5F14B3F8A2C1001 = {
+						CreatedOnToolsVersion = 26.6;
+						TestTargetID = C79E0CC6300DC8DB00B2AB85;
+					};
 				};
 			};
 			buildConfigurationList = C79E0CC2300DC8DB00B2AB85 /* Build configuration list for PBXProject "Learning" */;
 			developmentRegion = en;
 			hasScannedForEncodings = 0;
 			knownRegions = (
 				en,
 				Base,
 			);
 			mainGroup = C79E0CBE300DC8DB00B2AB85;
 			minimizedProjectReferenceProxies = 1;
 			preferredProjectObjectVersion = 77;
 			productRefGroup = C79E0CC8300DC8DB00B2AB85 /* Products */;
 			projectDirPath = "";
 			projectRoot = "";
 			targets = (
 				C79E0CC6300DC8DB00B2AB85 /* Learning */,
+				E6A0A203D5F14B3F8A2C1001 /* LearningTests */,
 			);
 		};
 /* End PBXProject section */
 
 /* Begin PBXResourcesBuildPhase section */
 		C79E0CC5300DC8DB00B2AB85 /* Resources */ = {
 			isa = PBXResourcesBuildPhase;
 			buildActionMask = 2147483647;
 			files = (
 			);
 			runOnlyForDeploymentPostprocessing = 0;
 		};
+		E6A0A206D5F14B3F8A2C1001 /* Resources */ = {
+			isa = PBXResourcesBuildPhase;
+			buildActionMask = 2147483647;
+			files = (
+			);
+			runOnlyForDeploymentPostprocessing = 0;
+		};
 /* End PBXResourcesBuildPhase section */
 
 /* Begin PBXSourcesBuildPhase section */
 		C79E0CC3300DC8DB00B2AB85 /* Sources */ = {
 			isa = PBXSourcesBuildPhase;
 			buildActionMask = 2147483647;
 			files = (
 			);
 			runOnlyForDeploymentPostprocessing = 0;
 		};
+		E6A0A204D5F14B3F8A2C1001 /* Sources */ = {
+			isa = PBXSourcesBuildPhase;
+			buildActionMask = 2147483647;
+			files = (
+			);
+			runOnlyForDeploymentPostprocessing = 0;
+		};
 /* End PBXSourcesBuildPhase section */
 
+/* Begin PBXTargetDependency section */
+		E6A0A20AD5F14B3F8A2C1001 /* PBXTargetDependency */ = {
+			isa = PBXTargetDependency;
+			target = C79E0CC6300DC8DB00B2AB85 /* Learning */;
+			targetProxy = E6A0A209D5F14B3F8A2C1001 /* PBXContainerItemProxy */;
+		};
+/* End PBXTargetDependency section */
+
 /* Begin XCBuildConfiguration section */
 		C79E0CD0300DC8DD00B2AB85 /* Debug */ = {
 			isa = XCBuildConfiguration;
 			buildSettings = {
 				ALWAYS_SEARCH_USER_PATHS = NO;
 				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
 				CLANG_ANALYZER_NONNULL = YES;
 				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
 				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
 				CLANG_ENABLE_MODULES = YES;
@@ -314,20 +389,69 @@
 				SUPPORTS_MACCATALYST = NO;
 				SWIFT_APPROACHABLE_CONCURRENCY = YES;
 				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
 				SWIFT_EMIT_LOC_STRINGS = YES;
 				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
 				SWIFT_VERSION = 5.0;
 				TARGETED_DEVICE_FAMILY = 1;
 			};
 			name = Release;
 		};
+		E6A0A20BD5F14B3F8A2C1001 /* Debug */ = {
+			isa = XCBuildConfiguration;
+			buildSettings = {
+				BUNDLE_LOADER = "$(TEST_HOST)";
+				CODE_SIGN_STYLE = Automatic;
+				CURRENT_PROJECT_VERSION = 1;
+				GENERATE_INFOPLIST_FILE = YES;
+				IPHONEOS_DEPLOYMENT_TARGET = 16.6;
+				LD_RUNPATH_SEARCH_PATHS = (
+					"$(inherited)",
+					"@executable_path/Frameworks",
+					"@loader_path/Frameworks",
+				);
+				MARKETING_VERSION = 1.0;
+				PRODUCT_BUNDLE_IDENTIFIER = com.li.test.learning.pronunciation.tests;
+				PRODUCT_NAME = "$(TARGET_NAME)";
+				SDKROOT = iphoneos;
+				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
+				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
+				SWIFT_VERSION = 5.0;
+				TARGETED_DEVICE_FAMILY = 1;
+				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Learning.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Learning";
+			};
+			name = Debug;
+		};
+		E6A0A20CD5F14B3F8A2C1001 /* Release */ = {
+			isa = XCBuildConfiguration;
+			buildSettings = {
+				BUNDLE_LOADER = "$(TEST_HOST)";
+				CODE_SIGN_STYLE = Automatic;
+				CURRENT_PROJECT_VERSION = 1;
+				GENERATE_INFOPLIST_FILE = YES;
+				IPHONEOS_DEPLOYMENT_TARGET = 16.6;
+				LD_RUNPATH_SEARCH_PATHS = (
+					"$(inherited)",
+					"@executable_path/Frameworks",
+					"@loader_path/Frameworks",
+				);
+				MARKETING_VERSION = 1.0;
+				PRODUCT_BUNDLE_IDENTIFIER = com.li.test.learning.pronunciation.tests;
+				PRODUCT_NAME = "$(TARGET_NAME)";
+				SDKROOT = iphoneos;
+				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
+				SWIFT_VERSION = 5.0;
+				TARGETED_DEVICE_FAMILY = 1;
+				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/Learning.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Learning";
+			};
+			name = Release;
+		};
 /* End XCBuildConfiguration section */
 
 /* Begin XCConfigurationList section */
 		C79E0CC2300DC8DB00B2AB85 /* Build configuration list for PBXProject "Learning" */ = {
 			isa = XCConfigurationList;
 			buildConfigurations = (
 				C79E0CD0300DC8DD00B2AB85 /* Debug */,
 				C79E0CD1300DC8DD00B2AB85 /* Release */,
 			);
 			defaultConfigurationIsVisible = 0;
@@ -335,14 +459,23 @@
 		};
 		C79E0CD2300DC8DD00B2AB85 /* Build configuration list for PBXNativeTarget "Learning" */ = {
 			isa = XCConfigurationList;
 			buildConfigurations = (
 				C79E0CD3300DC8DD00B2AB85 /* Debug */,
 				C79E0CD4300DC8DD00B2AB85 /* Release */,
 			);
 			defaultConfigurationIsVisible = 0;
 			defaultConfigurationName = Release;
 		};
+		E6A0A20DD5F14B3F8A2C1001 /* Build configuration list for PBXNativeTarget "LearningTests" */ = {
+			isa = XCConfigurationList;
+			buildConfigurations = (
+				E6A0A20BD5F14B3F8A2C1001 /* Debug */,
+				E6A0A20CD5F14B3F8A2C1001 /* Release */,
+			);
+			defaultConfigurationIsVisible = 0;
+			defaultConfigurationName = Release;
+		};
 /* End XCConfigurationList section */
 	};
 	rootObject = C79E0CBF300DC8DB00B2AB85 /* Project object */;
 }
diff --git a/Learning/Learning/LearningApp.swift b/Learning/Learning/LearningApp.swift
index 756c492..a9e0f61 100644
--- a/Learning/Learning/LearningApp.swift
+++ b/Learning/Learning/LearningApp.swift
@@ -2,16 +2,20 @@
 //  LearningApp.swift
 //  Learning
 //
 //  Created by CNCEMNV02 on 2026/7/20.
 //
 
 import SwiftUI
 
 @main
 struct LearningApp: App {
+    init() {
+        DatabaseManager.shared.initializeDatabase()
+    }
+
     var body: some Scene {
         WindowGroup {
-            ContentView()
+            MainPage()
         }
     }
 }

## Current File: Learning/Learning/MainPage.swift
import SwiftUI

enum MainTab: String, CaseIterable, Hashable {
    case home
    case calendar
    case profile
}

struct MainPage: View {
    static let defaultTab: MainTab = .home

    @State private var selectedTab: MainTab = Self.defaultTab

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
            .tabItem {
                Label("首页", systemImage: "house.fill")
            }
            .tag(MainTab.home)

            NavigationStack {
                Text("Calendar")
            }
            .tabItem {
                Label("日历", systemImage: "calendar")
            }
            .tag(MainTab.calendar)

            NavigationStack {
                Text("我的")
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
            .tag(MainTab.profile)
        }
    }
}

## Current File: Learning/LearningTests/NavigationShellTests.swift
import XCTest
import SwiftUI
@testable import Learning

final class NavigationShellTests: XCTestCase {
    func test_mainPage_defaults_to_home_tab() {
        XCTAssertEqual(MainPage.defaultTab, .home)
        XCTAssertEqual(MainTab.allCases, [.home, .calendar, .profile])
    }
}

## Current File: Learning/Learning.xcodeproj/xcshareddata/xcschemes/Learning.xcscheme
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "2660"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "C79E0CC6300DC8DB00B2AB85"
               BuildableName = "Learning.app"
               BlueprintName = "Learning"
               ReferencedContainer = "container:Learning.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "E6A0A203D5F14B3F8A2C1001"
               BuildableName = "LearningTests.xctest"
               BlueprintName = "LearningTests"
               ReferencedContainer = "container:Learning.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "C79E0CC6300DC8DB00B2AB85"
            BuildableName = "Learning.app"
            BlueprintName = "Learning"
            ReferencedContainer = "container:Learning.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "E6A0A203D5F14B3F8A2C1001"
               BuildableName = "LearningTests.xctest"
               BlueprintName = "LearningTests"
               ReferencedContainer = "container:Learning.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "C79E0CC6300DC8DB00B2AB85"
            BuildableName = "Learning.app"
            BlueprintName = "Learning"
            ReferencedContainer = "container:Learning.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "C79E0CC6300DC8DB00B2AB85"
            BuildableName = "Learning.app"
            BlueprintName = "Learning"
            ReferencedContainer = "container:Learning.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>

## DEVELOPMENT_TEAM Matches In project.pbxproj
328:				DEVELOPMENT_TEAM = 4JMPHJWURJ;
368:				DEVELOPMENT_TEAM = 7Q633Z98R6;
