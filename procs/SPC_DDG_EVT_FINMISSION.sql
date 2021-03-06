SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Gestionnaire de Stock de Masse
--			    Traitement Evènement Fin Mission
-- @v_mission : Mission
-- @v_demande : Demande
-- @v_cause   : Cause de fin mission
-- @v_agv     : AGV
-- @v_charge  : Bobine
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_EVT_FINMISSION]
	@v_mission         int,
	@v_demande         varchar(20),
	@v_cause           tinyint,
	@v_agv             tinyint,
	@v_charge          int
AS
BEGIN

declare @CODE_OK int,
		@CODE_KO int
declare @DMD_CAT_STOCK    int,
		@CAUSE_ANNULATION int,
		@DMD_ETAT_ANNULEE int,
		@DMD_ETAT_SOLDEE  int
		

declare @retour      int,
		@procStock   varchar(128),
		@chaineTrace varchar(7500)
declare @dmd_etat    int

set @CODE_OK = 0
set @CODE_KO = 1

DECLARE @ETAT_DMD_NOUVELLE		INT = 0
DECLARE @ETAT_DMD_EN_ATTENTE	INT = 1
DECLARE @ETAT_DMD_EN_COURS		INT = 2
DECLARE @ETAT_DMD_TERMINEE		INT = 3
DECLARE @ETAT_DMD_SUSPENDUE		INT = 11
DECLARE @ETAT_DMD_ANNULEE		INT = 12

set @retour = @CODE_OK
set @procStock = 'SPC_DDG_EVT_FINMISSION'

if exists( select 1 from SPC_DMD_REORGA_STOCK_GENERAL where SDG_IDDEMANDE = @v_demande )
begin
	if not exists( select 1 from INT_MISSION_VIVANTE where MIS_DEMANDE = @v_demande and MIS_IDMISSION <> @v_mission )
	begin
		if( @v_cause = @CAUSE_ANNULATION )
		begin
			set @dmd_etat = @DMD_ETAT_ANNULEE
		end
		else
		begin
			set @dmd_etat = @ETAT_DMD_TERMINEE
		end
		
		-- Changement d'état
		exec INT_ADDTRACESPECIFIQUE @procStock, '[DBGDMD]', 'SPC_DMD_CHG_ETAT'
		exec @retour = SPC_DDG_MODIFIER_DEMANDE @v_demande, @dmd_etat, NULL, NULL
		
		if( @retour <> @CODE_OK )
		begin
			set @chaineTrace = 'SPC_DMD_CHGTETAT : ' + CONVERT( varchar, ISNULL( @retour, -1 ) )
			exec INT_ADDTRACESPECIFIQUE @procStock, '[ERRDMD]', @chaineTrace
		end
	end
end

END


