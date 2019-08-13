"
Superclass of all commands that are applied to one image or multiple images.
"
Class {
	#name : #PhLImageCommand2,
	#superclass : #CmCommand,
	#category : #'PharoLauncher-Core-Commands2'
}

{ #category : #accessing }
PhLImageCommand2 >> canBeRun [ 
	^ self imagesPresenter hasSingleImageSelected
]

{ #category : #accessing }
PhLImageCommand2 >> imagesPresenter [
	^ self context
]