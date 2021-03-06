SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Modification de la position du skate d'entrée
	-- @v_ligne				: Identifiant de ligne
	-- @v_idPosition		: Position souhaitée
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMC_SETPOSITIONSKATE]
	@v_ligne			int,
	@v_idPosition		int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int

declare @retour int,
		@procStock varchar(128),
		@chaineTrace varchar(7500)

set @CODE_OK = 0
set @CODE_KO = 1

/*Initialisation des variables*/
declare @v_MotPosition int = 0
declare @v_ActiveMessage int = 0

/*Déclarations des constantes*/
declare @ACTION_DEPLACER_SKATE int = 11

set @retour = @CODE_OK
set @procStock = 'SPC_DMC_SETPOSITIONSKATE'
	
	SELECT @v_MotPosition = SLV_DEPLACERSKATE
		from SPC_ASSOCIATION_LIGNE_VARIABLEAUTOMATE
		where SLV_IDLIGNE = @v_ligne and SLV_ACTION = @ACTION_DEPLACER_SKATE

	EXEC INT_SETVARIABLEAUTOMATE @v_MotPosition, @v_idPosition

END


