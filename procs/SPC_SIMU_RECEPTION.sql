SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Création d'une bobine
	-- @v_numeroMessage  : Numéro de message
	-- @v_typeMessage    : Type de message
	-- @v_horodateMessage: Date du message
	-- @v_abonneInterne  : Abonné interne
	-- @v_abonneExterne  : Abonné externe
	-- @v_numeroVariable : ID variable
	-- @v_valeur         : Valeur variable
-- =============================================
CREATE PROCEDURE [dbo].[SPC_SIMU_RECEPTION]
AS
BEGIN

declare @CODE_OK int = 0,
		@CODE_KO int = 1

declare @retour int = @CODE_OK
declare	@procStock varchar(128) = 'SPC_REC_SIMULATION'
declare @chaineTrace varchar(7500)

-- DECLARATION DES VARIABLES
DECLARE @v_chg_idcharge int
DECLARE @v_chg_poids smallint
DECLARE @v_chg_hauteur smallint
DECLARE @v_chg_largeur smallint
DECLARE @v_chg_longueur smallint
DECLARE @v_chg_idsysteme bigint
DECLARE @v_chg_idbase bigint
DECLARE @v_chg_idsousbase bigint
DECLARE @v_chg_niveau tinyint
DECLARE @v_tag_idtypeagv tinyint
DECLARE @v_accesbase bit
DECLARE @v_chg_orientation smallint
DECLARE @v_chg_face bit
DECLARE @v_chg_code varchar(8000)
DECLARE @v_chg_idproduit varchar(20)
DECLARE @v_chg_idsymbole varchar(32)
DECLARE @v_chg_idlegende int
DECLARE @v_chg_idmenucontextuel int
DECLARE @v_chg_idvue int
DECLARE @v_chg_idgabarit tinyint
DECLARE @v_chg_idemballage tinyint
DECLARE @v_chg_stabilite smallint
DECLARE @v_chg_position tinyint
DECLARE @v_chg_vitessemaximale smallint
DECLARE @v_forcage bit

DECLARE @v_poids smallint
DECLARE @v_idmachine int
DECLARE @v_sensenroulement int
DECLARE @v_CodeABarre varchar(16)
DECLARE @v_StatutBobine int
DECLARE @v_DateEncollage datetime
DECLARE @v_grammage NUMERIC(4,2)
DECLARE @v_fournisseur INT

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

DECLARE @v_idsystemedepose bigint
DECLARE @v_idbasedepose bigint
DECLARE @v_idsousbasedepose bigint
DECLARE @v_idcharge int
DECLARE @v_rack int

DECLARE @SYSTEME_RECEPTION bigint = 65793
DECLARE @IDBASE_RECEPTION bigint = 144116291882516737
DECLARE @IDSOUSBASE_RECEPTION bigint = 65793

set @chaineTrace = 'DEBUT DE LA SIMULATION'
exec dbo.INT_ADDTRACESPECIFIQUE @procStock, 'SIMUL', @chaineTrace	

/*Suppression des charges du stock si celui ci est plein*/
/*IF (select count (1) from INT_ADRESSE where ADR_IDTYPEMAGASIN = 3 and ADR_MAGASIN = 2 and ADR_IDSOUSBASE <> 0 and (ADR_EMPLACEMENT_VIDE > 4 OR ADR_EMPLACEMENT_VIDE IS NULL)) < 3
BEGIN	
		declare C_CHARGE cursor for 
		select CHG_IDCHARGE from INT_CHARGE_VIVANTE
		inner join INT_ADRESSE on CHG_IDBASE = CHG_IDBASE
		where ADR_IDTYPEMAGASIN = 3 and ADR_MAGASIN = 2 and ADR_IDSOUSBASE <> 0
		open C_CHARGE
		fetch next from C_CHARGE INTO @v_idcharge
		while @@FETCH_STATUS = 0
		begin
			IF NOT EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE where MIS_IDCHARGE = @v_idcharge)
				EXEC INT_DELETECHARGE @v_idcharge
			fetch next from C_CHARGE INTO @v_idcharge	
		end
		close C_CHARGE
		deallocate C_CHARGE
END*/

/*Définition des caractéristiques charge*/
/*select * from SPC_CHG_LAIZE  /*648,720,967,1060,1286,1410*/
select * from SPC_CHG_DIAMETRE  /*1070,1250*/
select * from SPC_CHG_FOURNISSEUR /*1,2,3,4,5,6,7*/
select * from SPC_CHG_GRAMMAGE /*70.00,40.00,45.00,48.80,52.00,42.00,45.00,48.80,52.00,55.00*/*/

SET @v_chg_hauteur = NULL --1410 --720
SET @v_chg_largeur = NULL --1250
SET @v_chg_longueur = @v_chg_largeur
SET @v_grammage = 40.00
SET @v_fournisseur = 1
SET @v_idmachine = 1
SET @v_chg_poids = 1000

SELECT
	@v_sensenroulement = SME_ENROULEMENT
FROM SPC_ASSOCIATION_MACHINE_ENROULEMENT
WHERE SME_IDFOURNISSEUR = @v_fournisseur
AND SME_MACHINE = @v_idmachine


IF @retour = @CODE_OK
BEGIN
	declare @v_date datetime = DATEADD (day , -1, GETDATE())

	--Création d'une bobine aléatoire en Réception
	EXECUTE @retour = [dbo].[SPC_SIMU_CREERBOBINE] 
		@v_chg_idcharge OUTPUT	,NULL	,@v_chg_hauteur	,@v_chg_longueur	,NULL	, @v_grammage	,@v_fournisseur
		,@SYSTEME_RECEPTION	,@IDBASE_RECEPTION	,@IDSOUSBASE_RECEPTION

	
	/*EXECUTE @retour = [dbo].[SPC_SIMU_CREERBOBINE] 
		@v_chg_idcharge OUTPUT	,NULL	,NULL	,NULL	,NULL	,40.00	,1
		,@SYSTEME_RECEPTION	,@IDBASE_RECEPTION	,@IDSOUSBASE_RECEPTION*/

	/*
	EXECUTE @retour = [dbo].[SPC_CHG_CREER_BOBINE]	@v_chg_idcharge OUTPUT,
												@v_poids = @v_chg_poids,
												@v_laize = @v_chg_hauteur,
												@v_diametre = @v_chg_largeur,
												@v_idmachine = @v_idmachine,
												@v_grammage = @v_grammage,
												@v_fournisseur = @v_fournisseur,
												@v_idsysteme = @SYSTEME_RECEPTION,
												@v_idbase = @IDBASE_RECEPTION,
												@v_idsousbase = @IDSOUSBASE_RECEPTION,
												@v_sensenroulement = @v_sensenroulement,
												@v_CodeABarre = '012E4S6789012E4S',
												@v_StatutBobine = 0,
												@v_DateEncollage = @v_date*/
	IF @retour = @CODE_OK
	BEGIN
		set @v_idsystemedepose = 65793
		set @v_idbasedepose = 216174985432072192 -- STOCK_A (G)
		set @v_idsousbasedepose = 0

		set @v_idsystemeaffinage_depose = NULL
		set @v_idbaseaffinage_depose = NULL
		set @v_idsousbaseaffinage_depose = NULL


		EXECUTE @retour = [dbo].[INT_CREATEMISSIONPRISEDEPOSE]
		   @v_mis_idmission OUTPUT  ,@v_mis_iddemande = NULL   ,@v_mis_priorite = 0  ,@v_mis_dateecheance = NULL  ,@v_mis_idcharge = @v_chg_idcharge
		  ,@v_mis_idagv = NULL ,@v_mis_idlegende = NULL ,@v_mis_decharge = 0  ,@v_mis_idtypeagv = NULL  ,@v_mis_idtypeoutil = NULL
		  ,@v_tac_affinage_prise = 0
		  ,@v_tac_idsystemeexecution_prise = @SYSTEME_RECEPTION ,@v_tac_idbaseexecution_prise = @IDBASE_RECEPTION ,@v_tac_idsousbaseexecution_prise =  @IDSOUSBASE_RECEPTION
		  ,@v_tac_idsystemeaffinage_prise = NULL ,@v_tac_idbaseaffinage_prise = NULL ,@v_tac_idsousbaseaffinage_prise  = NULL
		  /*,@v_tac_accesbase_prise = 1 */,@v_tac_idoptionaction_prise = 0
		  ,@v_tac_affinage_depose = 2
		  ,@v_tac_idsystemeexecution_depose = @v_idsystemedepose  ,@v_tac_idbaseexecution_depose = @v_idbasedepose ,@v_tac_idsousbaseexecution_depose = @v_idsousbasedepose
		  ,@v_tac_idsystemeaffinage_depose = @v_idsystemeaffinage_depose,@v_tac_idbaseaffinage_depose = @v_idbaseaffinage_depose ,@v_tac_idsousbaseaffinage_depose = @v_idsousbaseaffinage_depose
		  ,@v_tac_accesbase_depose = NULL ,@v_tac_idoptionaction_depose = NULL

		IF @retour = @CODE_OK 
		BEGIN			
			set @chaineTrace = 'Création de de la mission : @v_mis_idmission' + CONVERT (varchar, ISNULL(@v_mis_idmission,''))
							 + ' , IDSYSTEME : ' + CONVERT (varchar, ISNULL(@v_idsystemedepose,''))
							 + ' , IDBASE : ' + CONVERT (varchar, ISNULL(@v_idbasedepose,''))
							 + ' , IDSSBASE : ' + CONVERT (varchar, ISNULL(@v_idsousbasedepose,''))
			EXECUTE INT_ADDTRACESPECIFIQUE @procStock, 'DEBUG', @chaineTrace
		END
		ELSE
		BEGIN
			set @chaineTrace = 'Erreur à la création de la mission : ' + CONVERT (varchar, ISNULL(@retour,''))
							 + ' , IDSYSTEMEDEPOSE : ' + CONVERT (varchar, ISNULL(@v_idsystemedepose,''))
							 + ' , IDBASEDEPOSE : ' + CONVERT (varchar, ISNULL(@v_idbasedepose,''))
							 + ' , IDSSBASEDEPOSE : ' + CONVERT (varchar, ISNULL(@v_idsousbasedepose,''))
							 + ' , IDSYSTEMEAFF : ' + CONVERT (varchar, ISNULL(@v_idsystemeaffinage_depose,''))
							 + ' , IDBASEAFF : ' + CONVERT (varchar, ISNULL(@v_idbaseaffinage_depose,''))
							 + ' , IDSSBASEAFF : ' + CONVERT (varchar, ISNULL(@v_idsousbaseaffinage_depose,''))
			EXECUTE INT_ADDTRACESPECIFIQUE @procStock, 'ERREUR', @chaineTrace
		END
	END
	ELSE
	BEGIN
		set @chaineTrace = 'Erreur à la création de la bobine : ' + CONVERT (varchar, ISNULL(@retour,''))
		EXECUTE INT_ADDTRACESPECIFIQUE @procStock, 'ERREUR', @chaineTrace
	END		
END
ELSE
BEGIN
	set @chaineTrace = 'Erreur à la création de la charge : ' + CONVERT (varchar, ISNULL(@retour,''))
	EXECUTE INT_ADDTRACESPECIFIQUE @procStock, 'ERREUR', @chaineTrace
END

-- REORGA DU STOCK


-- CREATION DE MISSIONS DE DESTOCKAGE


END

