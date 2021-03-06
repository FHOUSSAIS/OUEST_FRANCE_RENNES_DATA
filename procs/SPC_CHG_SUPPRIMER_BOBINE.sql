SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Suppression d'une bobine
	-- @v_idcharge			: identifiant bobine
-- =============================================
CREATE PROCEDURE [dbo].[SPC_CHG_SUPPRIMER_BOBINE]
	@v_idcharge INT
AS
BEGIN
-- Déclaration des constantes
DECLARE @CODE_OK TINYINT

DECLARE @TRCDMD_DELETE TINYINT

-- GMAPhase2
DECLARE @DMD_RCK_WIFAG INT,
		@DMD_MANUELLE INT,
		@DMD_AUTOMATIQUE Int,
		@CASE_PERMANENTE INT,
		@DEF_DMDCREATE_KO Int,
		@GRPDEF_GESTDMDWIFAG Int

-- Déclaration des variables
DECLARE @Retour INT,
		@v_local TINYINT,
		@v_transaction VARCHAR(200),
		@CodeFournisseur NCHAR(2),
		@PapeterieFournisseur VARCHAR(100),
		@PaysFournisseur VARCHAR(20),
		@TarifFournisseur SMALLINT, 
		@v_CodeGrammage NUMERIC(4,1), -- TINYINT FST-0710-01
		@ListeFournisseur tinyint,
		-- GMAPhase2
		@PoidsReel SMALLINT, 
		@StatutBobine INT, 
		@DateEncollage DATETIME,
		@Emplacement VARCHAR(20),
		@ValLaize INT,
		@ValDiametre INT,
		@AdrSysCase BIGINT, 
		@AdrBaseCase BIGINT, 
		@AdrSousBaseCase BIGINT,
		@IdFournPerm INT,
		@Error INT,
		@InfoPlus Varchar(200),
		@chg_idRehausse int

-- Initialisation des constantes
SET @CODE_OK = 0

SET @TRCDMD_DELETE = 6

-- GMAPhase2
SET @DMD_RCK_WIFAG = 1
SET @DMD_MANUELLE		= 0
Set @DMD_AUTOMATIQUE	= 1
SET @CASE_PERMANENTE = 1
Set @DEF_DMDCREATE_KO = 1
Set @GRPDEF_GESTDMDWIFAG = 6

-- Initialisation des variables
SET @Retour = @CODE_OK
SET @v_transaction = 'SPC_CHG_SUPPRIMERBOBINE'

-- Gestion des ouvertures de transactions
-----------------------------------------
	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Recherche des informations de la charge
	SELECT @CodeFournisseur = SCF_CODE, 
			@PapeterieFournisseur = SCF_IDTRADUCTION_PAPETERIE,
			@PaysFournisseur = SCF_IDTRADUCTION_PAYS,
			@TarifFournisseur = SCF_PRIX_TONNE,
			@ListeFournisseur = SCF_LISTE
	FROM SPC_CHG_FOURNISSEUR
	WHERE SCF_IDFOURNISSEUR = (SELECT SCB_IDFOURNISSEUR FROM SPC_CHARGE_BOBINE WHERE SCB_IDCHARGE = @v_idcharge)
	
	SELECT @v_CodeGrammage = SCB_GRAMMAGE FROM SPC_CHARGE_BOBINE WHERE SCB_IDCHARGE = @v_idcharge -- SCH_IDGRAMMAGE FST-0710-01
	
	SELECT @PoidsReel = SCB_POIDS_REEL,
			@StatutBobine = SCB_STATUT, 
			@DateEncollage = SCB_DATE_ENCOLLAGE,
			--@Emplacement = SCB_ Emplacement,
			@AdrSysCase = CHG_ADR_KEYSYS, @AdrBaseCase = CHG_ADR_KEYBASE, @AdrSousBaseCase = CHG_ADR_KEYSSBASE,
			@ValLaize = CHG_HAUTEUR,
			@ValDiametre = CHG_LARGEUR FROM SPC_CHARGE_BOBINE_VIVANTE
				inner join CHARGE on SCB_IDCHARGE = CHG_ID
			
	-- Suppression de la charge spécifique
	DELETE FROM SPC_CHARGE_BOBINE
		WHERE SCB_IDCHARGE = @v_idcharge
	SET @Retour = @@ERROR
	
	-- Suppression de la charge standard
	IF @Retour = @CODE_OK
		EXEC @Retour = INT_DELETECHARGE @v_idcharge

	/*-- Trace de la destruction de la bobine
	IF @Retour = @CODE_OK
	BEGIN
		EXEC @Retour = dbo.SPC_TRC_CHG_TRACEBOBINE @v_idcharge, @CodeFournisseur, @PapeterieFournisseur,
						@PaysFournisseur, @v_CodeGrammage, @TRCDMD_DELETE, @TarifFournisseur, @ListeFournisseur,
						@PoidsReel, @StatutBobine, @DateEncollage,NULL,NULL -- GMAPhase2
	END*/

	-- Si cette bobine était présente dans une case permanente du rack WIFAG
	-- => Il faut générer une demande automatique de réappro
	/*IF @Emplacement LIKE '%STW%'
	BEGIN
		-- recherche si la case est une case permanente
		-- et des infos nécessaires à cette réappro
		SELECT @IdFournPerm = SRA_TYPEFOURNISSEUR FROM SPC_STK_RACK 
			WHERE SRA_SYSTEME = @AdrSysCase AND SRA_BASE = @AdrBaseCase AND SRA_SOUSBASE = @AdrSousBaseCase
					AND SRA_IDRESA = @CASE_PERMANENTE
					
		IF @IdFournPerm > 0
			EXEC @Retour = dbo.SPC_DMD_CREATEDEMANDE_ALIMROTATIVE @DMD_RCK_WIFAG, @ValLaize, @ValDiametre,
							@v_CodeGrammage, NULL, NULL, NULL, @AdrSysCase, @AdrBaseCase, @AdrSousBaseCase,
							@DMD_AUTOMATIQUE, @Error out, @IdFournPerm, 2
		-- Traitement des codes error (Inutile de traiter tous les codes)
		IF @Retour <> @CODE_OK And @Error Not In (0, -5) 
		Begin
			Set @InfoPlus = 'Case du Rack : ' + @Emplacement
			Exec dbo.SPC_DEF_MONTEE_DEFAUT @DEF_DMDCREATE_KO, @GRPDEF_GESTDMDWIFAG, @InfoPlus
		End
	END
	*/
	
	-- Vidange Réhausse 1.01
	select @chg_idRehausse = SCR_NUMERO from SPC_CHARGE_REHAUSSE where SCR_IDBOBINE = @v_idcharge
	if( @@ROWCOUNT <> 0 )
	begin
		exec @retour = SPC_CHG_RETIRER_BOBINE @chg_idRehausse
		if( @Retour <> @CODE_OK )
		begin
			set @InfoPlus = 'SPC_CHG_RETIRER_BOBINE : ' + CONVERT( varchar, ISNULL( @retour, -1 ) )
			exec INT_ADDTRACESPECIFIQUE @v_transaction, 'ERREUR', @InfoPlus
		end
	end
	
-- Gestion des fermetures de transactions
-----------------------------------------
	IF @Retour <> @CODE_OK
	BEGIN
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
		
	RETURN @Retour
END

