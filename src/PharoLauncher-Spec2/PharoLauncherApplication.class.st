"
Application that allows users to choose a template from a set of templates (potentially on the web). From a template, the user can create a Pharo image and launch it. This application also list the existing images.

PharoLauncherApplication open
"
Class {
	#name : #PharoLauncherApplication,
	#superclass : #SpApplication,
	#instVars : [
		'imageRepository',
		'templateRepository',
		'imagesPresenter',
		'scriptsDirectory',
		'openAsWorld',
		'jobList'
	],
	#classVars : [
		'Default',
		'IsDeployed',
		'TemplateRepository',
		'TemplatesClearedOnStartup'
	],
	#classInstVars : [
		'pharoIcon'
	],
	#category : #'PharoLauncher-Spec2'
}

{ #category : #accessing }
PharoLauncherApplication class >> applicationName [

	^ 'pharo-launcher'
]

{ #category : #testing }
PharoLauncherApplication class >> beDeployed [
	IsDeployed := true
]

{ #category : #testing }
PharoLauncherApplication class >> beUndeployed [
	IsDeployed := false
]

{ #category : #accessing }
PharoLauncherApplication class >> default [
	^ Default ifNil: [ Default := self new ]
]

{ #category : #accessing }
PharoLauncherApplication class >> default: aPharoLauncherApplication [
	Default := aPharoLauncherApplication
]

{ #category : #settings }
PharoLauncherApplication class >> defaultInitializationScriptLocation [
	^ FileLocator launcherUserFilesLocation / 'scripts' 
]

{ #category : #settings }
PharoLauncherApplication class >> hardResetPersistanceState [
	^false
]

{ #category : #settings }
PharoLauncherApplication class >> hardResetPersistanceState: isClickedFromSettings [ 
	|packages|
	
	isClickedFromSettings ifFalse: [ ^ self ]. "Important: this code should not be run when loading stored preferences, else PharoLauncher deployment mode is set to not deployed!"
	
	SystemWindow allSubInstances do:[ :window | window delete].
	self inform: 'PharoLauncher state reset'.
	World doOneCycle.
	500 milliSeconds wait. "To help user perception that *something* was reset"
		
	packages := RPackageOrganizer default packages select:[ :package | 
		(package name includesSubstring: 'PharoLauncher') ].
	packages do: 
		[ :package | 
		package definedClasses 
			reject: [ :class | class = PhLStartupManager ] "Do not reset this class, else Pharo settings will not be loaded at startup and repository location couldbe wrong!"
			thenDo: [ :class | class classPool keys do: [ :key | class classPool at: key put: nil ] ] ].

	self openFull.
]

{ #category : #accessing }
PharoLauncherApplication class >> initializationScriptsDirectory [
	^ self default scriptsDirectory
]

{ #category : #accessing }
PharoLauncherApplication class >> initializationScriptsDirectory: aFileUrl [
	| directory |
	directory := aFileUrl asFileReference.
	self default scriptsDirectory: directory.
	^ directory ensureCreateDirectory
	
]

{ #category : #settings }
PharoLauncherApplication class >> initializationScriptsLocation [
	" Used to display a nice file url in settings browser"
	^ self initializationScriptsDirectory pathString 
	
]

{ #category : #settings }
PharoLauncherApplication class >> initializationScriptsLocation: aFileUrl [
	" Used to display a nice file url in settings browser"
	^ self initializationScriptsDirectory: aFileUrl
]

{ #category : #testing }
PharoLauncherApplication class >> isDeployed [
	^ IsDeployed ifNil: [ IsDeployed := false ]
]

{ #category : #'world menu' }
PharoLauncherApplication class >> menuCommandOn: aBuilder [ 
	<worldMenu> 

	(aBuilder item: #'Pharo Launcher')
		icon: self pharoIcon16x16;
		parent: #Tools;
		order: 110;
		action: [ self open ];
		withSeparatorAfter
]

{ #category : #opening }
PharoLauncherApplication class >> open [
	<script>
	
	^ self default
		openAsWorld: false;
		run
]

{ #category : #opening }
PharoLauncherApplication class >> openFull [ 
	<script>
	
	^ self default
		beOpenedAsWorld;
		run
]

{ #category : #'world menu' }
PharoLauncherApplication class >> pharoIcon16x16 [

	^ pharoIcon 
		ifNil: [ pharoIcon := (self iconNamed: #pharo) scaledToSize: 16@16 ].

]

{ #category : #'class initialization' }
PharoLauncherApplication class >> reset [
   Default ifNil: [ ^ self ].

   Default closeAllWindows.
	Default := nil
]

{ #category : #initialization }
PharoLauncherApplication class >> resetTemplateRepository [

	TemplateRepository := nil
]

{ #category : #settings }
PharoLauncherApplication class >> settingsOn: aBuilder [
	<systemsettings>
	<pharoLauncherSettings>
	(aBuilder group: #pharoLauncher)
		label: 'Pharo Launcher' translated;
		description: 'General application settings' translated;
		with: [ 
					(aBuilder setting: #templatesClearedOnStartup)
						label: 'Templates cleared at startup' translated;
						order: 20;
						target: self;
						description:
								'When enabled, Launcher startup clears the Templates List. ' , String cr
										, 'When disabled, Launcher startup retains the Templates List from last run.' translated.
		
					(aBuilder setting: #initializationScriptsLocation)
						label: 'Location of your image initialization scripts' translated;
						type: #Directory;
						parent: #pharoLauncher;
						target: self;
						order: 40;
						description: 'A directory where all your Pharo images initialization scripts will be saved (executed once at image creation)'.
		
					(aBuilder setting: #hardResetPersistanceState)
						label: 'Hard reset persistent state' translated;
						target: self;
						order: 70;
						description:
								'When PharoLauncher is updated through Monticello ' , 
								'sometimes you need to clear persistent state to pick up new changes.' , String cr, 
								'Clicking this box is a one-shot action, i.e. this state is also reset.', String cr, 
								'Note, all open windows are clsoed and the application restarted.'
								translated 
		
		]
]

{ #category : #accessing }
PharoLauncherApplication class >> templatesClearedOnStartup [
	^ TemplatesClearedOnStartup ifNil: [ TemplatesClearedOnStartup := false ].
]

{ #category : #settings }
PharoLauncherApplication class >> templatesClearedOnStartup: aBoolean [ 
	TemplatesClearedOnStartup := aBoolean
]

{ #category : #configuring }
PharoLauncherApplication >> beOpenedAsWorld [
	self openAsWorld: true
]

{ #category : #accessing }
PharoLauncherApplication >> defaultTemplateRepository [
	^ TemplateRepository ifNil: [ TemplateRepository := PhLTemplateGroupRepository default ]
]

{ #category : #accessing }
PharoLauncherApplication >> imageRepository [
	^ imageRepository
]

{ #category : #accessing }
PharoLauncherApplication >> imageRepository: aPhlImageRepository [
	imageRepository := aPhlImageRepository
]

{ #category : #announcements }
PharoLauncherApplication >> imageRepositoryChanged [
	imagesPresenter ifNotNil: #refresh
]

{ #category : #announcements }
PharoLauncherApplication >> imageRepositoryChanged: newImage [

	self imageRepositoryChanged.
	imagesPresenter ifNotNil: [ imagesPresenter selectImage: newImage ].
]

{ #category : #initialization }
PharoLauncherApplication >> initialize [

 	super initialize.
	"I want to register windows in order to be able to know which one is the last opened 
	 This can be use to push progress bars (they stack)."
	windows := OrderedCollection new. 
	openAsWorld := false.
	self
		useBackend: #Morphic 
		with: PharoLauncherConfiguration new.
	imageRepository :=  PhLDirectoryBasedImageRepository default.
	self templatesClearedOnStartup 
		ifTrue: [ self class resetTemplateRepository ].
	self resetTemplateRepository
]

{ #category : #'initialization - private' }
PharoLauncherApplication >> initializeImagesPresenter [
	^ imagesPresenter := PhLImagesPresenter
		newApplication: self
		model: imageRepository
]

{ #category : #accessing }
PharoLauncherApplication >> jobList [

	^ jobList ifNil: [ jobList := self newJobList  ]
]

{ #category : #events }
PharoLauncherApplication >> launchConfigurationEdited: aLaunchConfiguration [
	"set the last edited launch configuration in the toolbar "

	imagesPresenter refreshLaunchConfigurationList.
	aLaunchConfiguration isNullConfiguration 
		ifFalse: [ imagesPresenter selectConfiguration: aLaunchConfiguration ].
]

{ #category : #events }
PharoLauncherApplication >> newImageCreated [
	"We want to launch the freshly created image"
	imagesPresenter ifNotNil: [ imagesPresenter actionLaunch ]
]

{ #category : #configuring }
PharoLauncherApplication >> openAsWorld: aBoolean [
	openAsWorld := aBoolean
]

{ #category : #ui }
PharoLauncherApplication >> pushProgress: aString with: aBlock [

	self jobList pushJob: (SpJob newTitle: aString block: aBlock)
]

{ #category : #initialization }
PharoLauncherApplication >> resetTemplateRepository [
	templateRepository := nil.
]

{ #category : #accessing }
PharoLauncherApplication >> scriptsDirectory [
	^ (scriptsDirectory ifNil: [ 
		   self class initializationScriptsDirectory: self class defaultInitializationScriptLocation ])
		  ensureCreateDirectory
]

{ #category : #accessing }
PharoLauncherApplication >> scriptsDirectory: aFileReference [
	scriptsDirectory := aFileReference
]

{ #category : #ui }
PharoLauncherApplication >> shouldUpdateTemplateSources [

	^ self newConfirm
		title: 'Update';
		label: 'Update available for Pharo Launcher templates sources!';
		acceptLabel: 'Update';
		cancelLabel: 'Remind me later';
		openModal
]

{ #category : #ui }
PharoLauncherApplication >> showError: anError [

	self newInform 
		title: anError name;
		label: anError longDescription;
		openModalWithParent: self topWindow
]

{ #category : #running }
PharoLauncherApplication >> start [

	self initializeImagesPresenter.

	openAsWorld ifTrue: [ 
		self startFull.
		^ self ].

	imagesPresenter open
]

{ #category : #running }
PharoLauncherApplication >> startFull [
	
	imagesPresenter asWorldWindow 
		title: 'Pharo Launcher';
		open.
]

{ #category : #accessing }
PharoLauncherApplication >> templateRepository [
	^ 	templateRepository ifNil: [ templateRepository := self defaultTemplateRepository ] 
]

{ #category : #accessing }
PharoLauncherApplication >> templateRepository: aPhLTemplateGroupRepository [
	templateRepository := aPhLTemplateGroupRepository
]

{ #category : #accessing }
PharoLauncherApplication >> templatesClearedOnStartup [
	^ self class templatesClearedOnStartup
]

{ #category : #ui }
PharoLauncherApplication >> topWindow [
	"The window that will accept a modal window related to it. 
	 This is usually the top window, but in case of stacking dialogs, some times this is lost. 
	 In that case, I want still choose one window"
	
	super topWindow ifNotNil: [ :topWindow | ^ topWindow ].
	^ self windows 
		ifNotEmpty: [ :aCollection | aCollection last ]
		ifEmpty: [ nil ]
]
