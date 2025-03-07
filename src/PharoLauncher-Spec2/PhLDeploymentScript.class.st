"
I'm responsible for preparing the image to be a Pharo Launcher image. Namely, I make sure that

- one Pharo Launcher window is open and centered
- this window can't be closed easily
- the user-defined startup scripts are not executed
"
Class {
	#name : #PhLDeploymentScript,
	#superclass : #Object,
	#classVars : [
		'DefaultDebuggerRank',
		'Save'
	],
	#category : #'PharoLauncher-Spec2'
}

{ #category : #actions }
PhLDeploymentScript class >> activateDeprecationWarnings [
	Deprecation raiseWarning: true
]

{ #category : #actions }
PhLDeploymentScript class >> activateErrorCatching [
	DefaultDebuggerRank := StDebugger rank.
	StDebugger rank: 9.
]

{ #category : #actions }
PhLDeploymentScript class >> activateLostChangesDetector [
	EpLostChangesDetector initialize
]

{ #category : #actions }
PhLDeploymentScript class >> activateStartupActions [
	StartupPreferencesLoader allowStartupScript: true.
]

{ #category : #actions }
PhLDeploymentScript class >> addToStartupList [
	PhLStartupManager addToLauncherStartUpList: self
]

{ #category : #actions }
PhLDeploymentScript class >> askForConfirmationWhenQuitting [
	self flag: 'TODO'.
	"Since UserManager is now over, there is no clean way to avoid warning when we juast ask to quit the image. More general, there should be a way to have an image in read/only mode"
	Save := true
]

{ #category : #actions }
PhLDeploymentScript class >> closeAllWindows [
	"We make sure we always close without asking for confirmation. It looks like #closeAllWindowsDiscardingChanges doesn't work as a startup action."
	[ World closeAllWindowsDiscardingChanges ]
		on: ProvideAnswerNotification
		do: [ :err | err return: false ].
	World submorphs do: #delete.
	PharoLauncherApplication default closeAllWindows.
]

{ #category : #actions }
PhLDeploymentScript class >> closeWindowsAndOpenDevelopmentEnvironment [
	PanelMorph allInstancesDo: [ :pm | pm delete ].
	self closeAllWindows.
	TaskbarMorph reset.
	MenubarMorph reset.
	Smalltalk tools workspace openContents: 'PharoLauncherApplication open.'.

	"PanelMorph comes from use of #openWorldWithSpec"
]

{ #category : #actions }
PhLDeploymentScript class >> closeWindowsAndOpenLauncher [
	self 
		closeAllWindows;
		openLauncher
]

{ #category : #actions }
PhLDeploymentScript class >> deactivateDeprecationWarnings [
	Deprecation raiseWarning: false
]

{ #category : #actions }
PhLDeploymentScript class >> deactivateErrorCatching [
	StDebugger rank: DefaultDebuggerRank
]

{ #category : #actions }
PhLDeploymentScript class >> deactivateLostChangesDetector [
	SessionManager default unregisterClassNamed: #EpLostChangesDetector
]

{ #category : #actions }
PhLDeploymentScript class >> deactivateStartupActions [
	StartupPreferencesLoader allowStartupScript: false.
]

{ #category : #settings }
PhLDeploymentScript class >> developmentEnvironmentEnabled [
	^ self isDeployed not
]

{ #category : #settings }
PhLDeploymentScript class >> developmentEnvironmentEnabled: aBoolean [
	aBoolean 
		ifTrue: 
		[	self undoAll.  	
			self closeWindowsAndOpenDevelopmentEnvironment 
		]
		ifFalse: 
		[ 	self doAll. 
			self closeWindowsAndOpenLauncher.
			self isDeployed ifFalse: [ Smalltalk snapshot: true andQuit: false "save deployed mode" ]
		].
]

{ #category : #public }
PhLDeploymentScript class >> doAll [
	self
		closeAllWindows;
		removeAllMorphs;
		deactivateStartupActions;
		dontRaiseWarningForMissingChangesOrSourcesFiles;
		deactivateDeprecationWarnings;
		deactivateLostChangesDetector;
		activateErrorCatching;
		makeDeployed;
		resetImageDescriptionUpdater;
		addToStartupList;
		dontAskForConfirmationWhenQuitting;
		setProgressBarSizeAndPosition
]

{ #category : #actions }
PhLDeploymentScript class >> doRaiseWarningForMissingChangesOrSourcesFiles [
	PharoFilesOpener default setInformAboutReadOnlyChanges.
]

{ #category : #actions }
PhLDeploymentScript class >> dontAskForConfirmationWhenQuitting [
	self flag: 'TODO'.
	"Since UserManager is now over, there is no clean way to avoid warning when we juast ask to quit the image. More general, there should be a way to have an image in read/only mode"
	Save := false
]

{ #category : #actions }
PhLDeploymentScript class >> dontRaiseWarningForMissingChangesOrSourcesFiles [
	PharoFilesOpener default unsetInformAboutReadOnlyChanges.
]

{ #category : #initialization }
PhLDeploymentScript class >> initialize [
	Save := false
]

{ #category : #public }
PhLDeploymentScript class >> initializeLibgit [
	LGitLibrary uniqueInstance initializeLibGit2
]

{ #category : #settings }
PhLDeploymentScript class >> isDeployed [
	^ PharoLauncherApplication isDeployed
]

{ #category : #'system startup' }
PhLDeploymentScript class >> launcherStartUp [
	self isDeployed
		ifTrue: [ self closeWindowsAndOpenLauncher ]
]

{ #category : #'system startup' }
PhLDeploymentScript class >> launcherStartUpPriority [
	^ 300
]

{ #category : #settings }
PhLDeploymentScript class >> makeDeployed [
	PharoLauncherApplication beDeployed
]

{ #category : #settings }
PhLDeploymentScript class >> makeUndeployed [
	PharoLauncherApplication beUndeployed
]

{ #category : #actions }
PhLDeploymentScript class >> openLauncher [
	PharoLauncherApplication openFull
]

{ #category : #actions }
PhLDeploymentScript class >> quitSession [
	self flag: 'TODO'.
	"Since UserManager is now over, there is no clean way to avoid warning when we juast ask to quit the image. More general, there should be a way to have an image in read/only mode"
	Save 
		ifTrue: [Smalltalk snapshot: true andQuit: true] 
		ifFalse: [Smalltalk snapshot: false andQuit: true]
 
]

{ #category : #actions }
PhLDeploymentScript class >> removeAllMorphs [ 
	" Don't keep unnecessary stuff.
	  Also there is a bug popping with FT2 when trying to send #changed to the MenuBar. Removing morphs will workaround this problem"
	World removeAllMorphs
]

{ #category : #actions }
PhLDeploymentScript class >> removeFromStartupList [
	[ PhLStartupManager removeFromStartupList: self ]
		on: NotFound 
		do: [ :e | "Not there, just ignore!" ]
]

{ #category : #actions }
PhLDeploymentScript class >> resetImageDescriptionUpdater [
	PhLImageDescriptionUpdater default terminateProcess.
	PhLImageDescriptionUpdater reset.
]

{ #category : #actions }
PhLDeploymentScript class >> resetPharoLauncherIcebergRepositoryLocation [
	| phLCorePackage |
	phLCorePackage := RPackageOrganizer default packageNamed: 'PharoLauncher-Core'.
	(IceRepository registeredRepositoryIncludingPackage: phLCorePackage)
		name: 'pharo-launcher';
		location: nil
]

{ #category : #actions }
PhLDeploymentScript class >> setProgressBarSizeAndPosition [
	"increase size and reposition progress bar to the middle of screen to make it more visible"
	SystemProgressMorph uniqueInstance
		minWidth: 600;
		minHeight: 50;
		layoutInset: 30 @ 20;
		position: 150 @ 200	
]

{ #category : #settings }
PhLDeploymentScript class >> settingsOn: aBuilder [
	<systemsettings>
	<pharoLauncherSettings>
	(aBuilder setting: #developmentEnvironmentEnabled) 
		parent: #pharoLauncher;
		target: self;
		order: 60;
		label: 'Enable development environment' translated;
		description: 'Missing a feature?  Hey come join in!  Add your custom feature.
When enabled, exits the Launcher application into the Pharo development environment.
When disabled, closes all windows and locks Launcher as the only running application. ' translated.
]

{ #category : #public }
PhLDeploymentScript class >> undoAll [
	self
		activateStartupActions;
		doRaiseWarningForMissingChangesOrSourcesFiles;
		activateDeprecationWarnings;
		activateLostChangesDetector;
		deactivateErrorCatching;
		makeUndeployed;
		removeFromStartupList;
		askForConfirmationWhenQuitting;
		initializeLibgit
]
