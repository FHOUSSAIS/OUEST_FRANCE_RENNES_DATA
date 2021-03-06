SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Création d'une charge spécifique type bobine
-- =============================================
CREATE PROCEDURE [dbo].[SPC_CHG_CREER_BOBINE]
	@v_idcharge int out,
	@v_poids int = NULL,
	@v_laize int = NULL,
	@v_diametre int = NULL,
	@v_sensenroulement int = NULL,
	@v_idmachine int = NULL,
	@v_grammage numeric(5,2) = NULL,
	@v_fournisseur int = NULL,
	@v_idsysteme bigint = NULL,
	@v_idbase bigint = NULL,
	@v_idsousbase bigint = NULL,
	@v_CodeABarre varchar(16) = NULL,
	@v_StatutBobine INT = 1,
	@v_DateEncollage DATETIME = NULL
AS

BEGIN
-- Déclaration des constantes
-----------------------------
	DECLARE
		@CODE_OK tinyint,
		@CODE_KO tinyint,
		@CODE_KO_FOURNISSEUR_INCONNU TINYINT,
		@CODE_KO_GRAMMAGE_INCONNU TINYINT,
		
		@TRCDMD_CREATE TINYINT
		
	DECLARE @DEF_FOURNISSEUR_INCONNU TINYINT
	DECLARE @CATDEF_GEST_BOBINES TINYINT
	DECLARE @PROCESS_RECEPTION INT	
	declare @ChaineTrace varchar(200)
	
-- Déclaration des variables
----------------------------
	DECLARE @v_transaction varchar(32),
			@v_local bit,
			@v_retour INT,
			@v_TarifFournisseur SMALLINT,
			@SymboleBobine varchar(32)
	DECLARE @InfoPlus VARCHAR(200)

	DECLARE	@v_Poids_Theorique INT,
		@v_Poids_Brut INT,
		@v_Poids_Reel INT,
		@v_NomMachine INT,
		@v_Valorisation NUMERIC(6,2),
		@v_Statut int,
		@v_DateStockage DATETIME,
		@v_idCarton int,
		@v_orientation INT,
		@v_symbole VARCHAR(32)
	
-- Définition des constantes
-----------------------------------------
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_FOURNISSEUR_INCONNU = 2
	SET @CODE_KO_GRAMMAGE_INCONNU	 = 3
	
	SET @TRCDMD_CREATE = 4
	
	SET @CATDEF_GEST_BOBINES	= 2
	SET @DEF_FOURNISSEUR_INCONNU = 5
	SET @PROCESS_RECEPTION = 2

-- Initialisation des variables
-------------------------------
	set @v_transaction = 'SPC_CHG_CREER_BOBINE'
	SET @SymboleBobine = NULL
	SET @v_retour = @CODE_OK
	SET @v_idcharge = 0

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Gestion des ouvertures de transactions
-----------------------------------------
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END

	SELECT @v_orientation = SSE_ORIENTATION from SPC_CHG_SENSENROULEMENT where SSE_SENSENROULEMENT = @v_sensenroulement

	-- Définition du symbole
	SELECT @v_symbole = 'BOB' + SPC_CHG_DIAMETRE.SCD_SYMBOLE from SPC_CHG_DIAMETRE where SPC_CHG_DIAMETRE.SCD_DIAMETRE = @v_diametre
	SELECT @v_symbole = @v_symbole + '_' + SPC_CHG_LAIZE.SCL_SYMBOLE from SPC_CHG_LAIZE where SPC_CHG_LAIZE.SCL_LAIZE = @v_laize
	
	set @chaineTrace = 'Création du symbole : ' + @v_symbole
	EXECUTE INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @chaineTrace

	-- CREATION d'UNE BOBINE EN CONV RECEPTION + mission de stockage
	EXECUTE @v_retour = [dbo].[INT_CREATECHARGE] @v_idcharge OUTPUT
										  ,@v_chg_poids = @v_poids ,@v_chg_hauteur = @v_laize ,@v_chg_largeur = @v_diametre ,@v_chg_longueur = @v_diametre
										  ,@v_chg_idsysteme = @v_idsysteme ,@v_chg_idbase = @v_idbase ,@v_chg_idsousbase = @v_idsousbase
										  ,@v_chg_niveau = NULL ,@v_tag_idtypeagv = NULL ,@v_accesbase  = NULL ,@v_chg_orientation = @v_orientation ,@v_chg_face   = 0
										  ,@v_chg_code  = NULL ,@v_chg_idproduit  = NULL ,@v_chg_idsymbole  = @v_symbole ,@v_chg_idlegende  = NULL
										  ,@v_chg_idmenucontextuel  = NULL ,@v_chg_idvue  = NULL ,@v_chg_idgabarit  = NULL ,@v_chg_idemballage   = NULL
										  ,@v_chg_stabilite  = NULL ,@v_chg_position  = NULL ,@v_chg_vitessemaximale  = 0 ,@v_forcage = NULL

	IF @v_retour = @CODE_OK
	BEGIN
		/*Définition des spécificitées de la bobine*/
		INSERT INTO [dbo].[SPC_CHARGE_BOBINE]
           ([SCB_IDCHARGE]
           ,[SCB_POIDS_THEORIQUE]
           ,[SCB_POIDS_BRUT]
           ,[SCB_POIDS_NET]
           ,[SCB_NOMMACHINE]
           ,[SCB_GRAMMAGE]
           ,[SCB_IDFOURNISSEUR]
           ,[SCB_CAB]
           ,[SCB_VALORISATION]
           ,[SCB_STATUT]
           ,[SCB_DATE_STOCKAGE]
           ,[SCB_DATE_ENCOLLAGE]
           ,[SCB_IDCARTON]
		   ,[SCB_LAIZE]
		   ,[SCB_DIAMETRE])
		VALUES
           (@v_idcharge
           ,@v_poids
           ,@v_poids
           ,@v_poids
           ,@v_idmachine
           ,@v_grammage
           ,@v_fournisseur
           ,@v_CodeABarre
           ,@v_Valorisation
           ,@v_StatutBobine
           ,GETDATE()
           ,@v_DateEncollage
           ,@v_idCarton
		   ,@v_laize
		   ,@v_diametre)
	END
	ELSE
	BEGIN
		set @chaineTrace = 'Création de la charge : @v_idcharge' + CONVERT (varchar, ISNULL(@v_idcharge,''))
						 + ' , IDSYSTEME : ' + CONVERT (varchar, ISNULL(@v_idsysteme,''))
						 + ' , IDBASE : ' + CONVERT (varchar, ISNULL(@v_idbase,''))
						 + ' , IDSSBASE : ' + CONVERT (varchar, ISNULL(@v_idsousbase,''))
		EXECUTE INT_ADDTRACESPECIFIQUE @v_transaction, 'DEBUG', @chaineTrace
	END

-- Gestion des fermetures de transactions
-----------------------------------------
	IF @v_retour <> @CODE_OK
	BEGIN
		SET @v_idcharge = 0
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
	RETURN @v_retour

END

