SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Author:		G.MASSARD
-- Create date: 09/07/2010
-- Description:	Renvoie l'état du Convoyeur de DEMACULAGE ou du basculeur
-- =============================================
CREATE FUNCTION [dbo].[SPC_DMC_GETETATLIGNE]
(
	@v_IdLigne INT
)
RETURNS int
AS
BEGIN
	DECLARE @VAR_ETAT_DEMACULAGE_5 INT,
			@VAR_ETAT_DEMACULAGE_6 INT

	declare @cvy_etat int,
			@VarEtatConvoyeur int,
			@LectureEnCours Int,
			@EtatInterface Int,
			@Simulation Int
	
	SET @VAR_ETAT_DEMACULAGE_5 = 1
	SET @VAR_ETAT_DEMACULAGE_6 = 14
	
	SET @VarEtatConvoyeur = NULL
	SET @cvy_etat = NULL
	
	IF @v_IdLigne = 5
		SET @VarEtatConvoyeur = @VAR_ETAT_DEMACULAGE_5
	IF @v_IdLigne = 6
		SET @VarEtatConvoyeur = @VAR_ETAT_DEMACULAGE_6
		
	SELECT @Simulation = CONVERT(INT,PAR_VAL) FROM PARAMETRE WHERE PAR_NOM='SPC_SIMULATION'
	
	Select @cvy_etat = VAU_VALEUR, @LectureEnCours = VAU_READ, @EtatInterface = VAU_QUALITE 
		From INT_VARIABLE_AUTOMATE
			Where VAU_IDVARIABLEAUTOMATE = @VarEtatConvoyeur

	If @Simulation=1
		Set @cvy_etat = 1

	-- non prise en compte de l'info tant qu'elle n'est pas lue
	-- non prise en compte de l'info si l'interface n'est pas active
	if (@LectureEnCours = 1 or @EtatInterface = 0) And (@Simulation=0)
		Set @cvy_etat = 0
		
	return @cvy_etat
END

