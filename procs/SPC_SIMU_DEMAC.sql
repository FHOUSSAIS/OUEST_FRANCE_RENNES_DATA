SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Simulation de déstockage
-- =============================================
CREATE PROCEDURE [dbo].[SPC_SIMU_DEMAC]
AS
BEGIN

declare @CODE_OK int = 0,
		@CODE_KO int = 1

declare @retour int
declare	@procStock varchar(128) = 'SPC_SIMU_DEMAC'
declare @chaineTrace varchar(7500)

-- DECLARATION DES VARIABLES
DECLARE @v_chg_idcharge int
DECLARE @v_mis_idmission int
DECLARE @v_mis_iddemande varchar(20)
DECLARE @v_mis_priorite int
DECLARE @v_mis_dateecheance datetime
DECLARE @v_mis_idcharge int
DECLARE @v_mis_idagv tinyint
DECLARE @v_mis_idlegende int
DECLARE @v_mis_decharge bit
DECLARE @v_mis_idtypeagv tinyint
DECLARE @v_mis_idtypeoutil tinyint
DECLARE @v_tac_affinage_prise tinyint
DECLARE @v_tac_idsystemeexecution_prise bigint
DECLARE @v_tac_idbaseexecution_prise bigint
DECLARE @v_tac_idsousbaseexecution_prise bigint
DECLARE @v_tac_idsystemeaffinage_prise bigint
DECLARE @v_tac_idbaseaffinage_prise bigint
DECLARE @v_tac_idsousbaseaffinage_prise bigint
DECLARE @v_tac_accesbase_prise bit
DECLARE @v_tac_idoptionaction_prise tinyint
DECLARE @v_tac_affinage_depose tinyint
DECLARE @v_tac_idsystemeexecution_depose bigint
DECLARE @v_tac_idbaseexecution_depose bigint
DECLARE @v_tac_idsousbaseexecution_depose bigint
DECLARE @v_tac_idsystemeaffinage_depose bigint
DECLARE @v_tac_idbaseaffinage_depose bigint
DECLARE @v_tac_idsousbaseaffinage_depose bigint
DECLARE @v_tac_accesbase_depose bit
DECLARE @v_tac_idoptionaction_depose tinyint
DECLARE @v_idsystemeaffinage_depose bigint
DECLARE @v_idbaseaffinage_depose bigint
DECLARE @v_idsousbaseaffinage_depose bigint

DECLARE @v_idsystemeprise bigint
DECLARE @v_idbaseprise bigint
DECLARE @v_idsousbaseprise bigint
DECLARE @v_idsystemedepose bigint
DECLARE @v_idbasedepose bigint
DECLARE @v_idsousbasedepose bigint

DECLARE @demac int

set @chaineTrace = 'DEBUT DE LA SIMULATION'
exec dbo.INT_ADDTRACESPECIFIQUE @procStock, 'SIMUL', @chaineTrace	

		/*Recherche d'une charge à transmettre vers les DEMAC*/
		SELECT @v_chg_idcharge = CHG_IDCHARGE, @v_idsystemeprise = ADR_IDSYSTEME, @v_idbaseprise = ADR_IDBASE, @v_idsousbaseprise = ADR_IDSOUSBASE
			 from INT_CHARGE_VIVANTE
		inner join INT_ADRESSE on ADR_IDSYSTEME = CHG_IDSYSTEME and ADR_IDBASE = CHG_IDBASE and ADR_IDSOUSBASE = CHG_IDSOUSBASE
		where ADR_MAGASIN = 2 and ADR_IDTYPEMAGASIN = 3 and ADR_IDSOUSBASE <> 0
		order by ADR_RACK desc, CHG_POSITIONPROFONDEUR desc, CHG_POSITIONNIVEAU

		IF NOT EXISTS (select 1 from INT_TACHE_MISSION where TAC_POSITION = 1 
				and TAC_IDSYSTEMEEXECUTION = @v_idsystemeprise and TAC_IDBASEEXECUTION = @v_idbaseprise and TAC_IDSOUSBASEEXECUTION = @v_idsousbaseprise
				and TAC_IDETATTACHE < 5
		)
		BEGIN
			SET @demac = ROUND(RAND() +5,0) 
			SELECT @v_idsystemedepose = ADR_IDSYSTEME, @v_idbasedepose = ADR_IDBASE, @v_idsousbasedepose = ADR_IDSOUSBASE 
				from INT_ADRESSE where ADR_MAGASIN = 3 and ADR_ALLEE = 1 and  ADR_COULOIR = @demac and ADR_COTE = 1		-- DEMAC 5
				--from INT_ADRESSE where ADR_MAGASIN = 3 and ADR_ALLEE = 1 and  ADR_COULOIR = 6 and ADR_COTE = 1	-- DEMAC 6

			EXECUTE @retour = [dbo].[INT_CREATEMISSIONPRISEDEPOSE]
			   @v_mis_idmission OUTPUT  ,@v_mis_iddemande = NULL   ,@v_mis_priorite = 0  ,@v_mis_dateecheance = NULL  ,@v_mis_idcharge = NULL
			  ,@v_mis_idagv = NULL ,@v_mis_idlegende = NULL ,@v_mis_decharge = 0  ,@v_mis_idtypeagv = NULL  ,@v_mis_idtypeoutil = NULL
			  ,@v_tac_affinage_prise = 0
			  ,@v_tac_idsystemeexecution_prise = @v_idsystemeprise ,@v_tac_idbaseexecution_prise = @v_idbaseprise ,@v_tac_idsousbaseexecution_prise =  @v_idsousbaseprise
			  ,@v_tac_idsystemeaffinage_prise = NULL ,@v_tac_idbaseaffinage_prise = NULL ,@v_tac_idsousbaseaffinage_prise  = NULL
			  /*,@v_tac_accesbase_prise = 1 */,@v_tac_idoptionaction_prise = NULL
			  ,@v_tac_affinage_depose = 0
			  ,@v_tac_idsystemeexecution_depose = @v_idsystemedepose  ,@v_tac_idbaseexecution_depose = @v_idbasedepose ,@v_tac_idsousbaseexecution_depose = @v_idsousbasedepose
			  ,@v_tac_idsystemeaffinage_depose = NULL,@v_tac_idbaseaffinage_depose = NULL ,@v_tac_idsousbaseaffinage_depose = NULL 
			  /*,@v_tac_affinage_depose = 2
			  ,@v_tac_idsystemeexecution_depose = @v_idsystemedepose  ,@v_tac_idbaseexecution_depose = @v_idbasedepose ,@v_tac_idsousbaseexecution_depose = @v_idsousbasedepose
			  ,@v_tac_idsystemeaffinage_depose = @v_idsystemeaffinage_depose,@v_tac_idbaseaffinage_depose = @v_idbaseaffinage_depose ,@v_tac_idsousbaseaffinage_depose = @v_idsousbaseaffinage_depose*/
			  /*,@v_tac_accesbase_depose = 0*/ ,@v_tac_idoptionaction_depose = NULL

			IF @retour = @CODE_OK 
			BEGIN			
				set @chaineTrace = 'Création de de la mission : @v_mis_idmission' + CONVERT (varchar, ISNULL(@v_mis_idmission,''))
								 + ' , IDSYSTEME PRISE: ' + CONVERT (varchar, ISNULL(@v_idsystemeprise,''))
								 + ' , IDBASE PRISE: ' + CONVERT (varchar, ISNULL(@v_idbaseprise,''))
								 + ' , IDSSBASE PRISE ' + CONVERT (varchar, ISNULL(@v_idsousbaseprise,''))
								 + ' , IDSYSTEME DEPOSE: ' + CONVERT (varchar, ISNULL(@v_idsystemedepose,''))
								 + ' , IDBASE DEPOSE: ' + CONVERT (varchar, ISNULL(@v_idbasedepose,''))
								 + ' , IDSSBASE : DEPOSE' + CONVERT (varchar, ISNULL(@v_idsousbasedepose,''))
				EXECUTE INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @chaineTrace
			END
			ELSE
			BEGIN
				set @chaineTrace = 'Erreur à la création de la mission : ' + CONVERT (varchar, ISNULL(@retour,''))
								 + ' , IDSYSTEME PRISE: ' + CONVERT (varchar, ISNULL(@v_idsystemeprise,''))
								 + ' , IDBASE PRISE: ' + CONVERT (varchar, ISNULL(@v_idbaseprise,''))
								 + ' , IDSSBASE PRISE ' + CONVERT (varchar, ISNULL(@v_idsousbaseprise,''))
								 + ' , IDSYSTEME DEPOSE: ' + CONVERT (varchar, ISNULL(@v_idsystemedepose,''))
								 + ' , IDBASE DEPOSE: ' + CONVERT (varchar, ISNULL(@v_idbasedepose,''))
								 + ' , IDSSBASE DEPOSE ' + CONVERT (varchar, ISNULL(@v_idsousbasedepose,''))
				EXECUTE INT_ADDTRACESPECIFIQUE @procStock, 'ERREUR', @chaineTrace
			END
		END
END

