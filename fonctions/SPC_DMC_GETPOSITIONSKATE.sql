SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Position du Skate d’entrée
-- @v_IdLigne	: Ligne de la démac
-- =============================================
CREATE FUNCTION [dbo].[SPC_DMC_GETPOSITIONSKATE]
(
	@v_IdLigne INT
)
RETURNS int
AS
BEGIN
	DECLARE @VAR_POS_DEMAC INT
			
	declare @VarPositionSkate int,	
			@LectureEnCours Int,
			@EtatInterface Int,
			@Simulation Int

	IF @v_IdLigne = 5
		SET @VAR_POS_DEMAC = 3 -- Action 12
	IF @v_IdLigne = 6
		SET @VAR_POS_DEMAC = 53 -- Action 12

	--SELECT @Simulation = CONVERT(INT,PAR_VAL) FROM PARAMETRE WHERE PAR_NOM='SPC_SIMULATION'

	Select @VarPositionSkate = VAU_VALEUR, @LectureEnCours = VAU_READ, @EtatInterface = VAU_QUALITE 
		From INT_VARIABLE_AUTOMATE
			Where VAU_IDVARIABLEAUTOMATE = @VAR_POS_DEMAC
	
	/*If @Simulation=1
		Set @VarPositionSkate = 1*/

	-- non prise en compte de l'info tant qu'elle n'est pas lue
	-- non prise en compte de l'info si l'interface n'est pas active
	if (@LectureEnCours = 1 or @EtatInterface = 0) And (@Simulation=0)
		Set @VarPositionSkate = 0

	return @VarPositionSkate
END

