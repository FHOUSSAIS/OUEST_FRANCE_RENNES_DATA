SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Valoriser une bobine
	-- @v_idcharge			: identifiant bobine
-- =============================================

CREATE PROCEDURE [dbo].[SPC_CHG_VALORISER]
	@v_idcharge int
AS

BEGIN

-- Déclaration des variables
-----------------------------
declare @v_transaction varchar(20),
		@v_retour int,
		@v_local int,
		@chaineTrace varchar (200)

declare @v_valorisation numeric(6,2),
		@v_prix_tonne	int,
		@v_poids		int


-- Déclaration des constantes
-----------------------------
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_FOURNISSEUR_INCONNU TINYINT

-- Définition des constantes
-----------------------------------------
SET @CODE_OK = 0
SET @CODE_KO = 1
SET @CODE_KO_FOURNISSEUR_INCONNU = 2


-- Initialisation des variables
-------------------------------
set @v_transaction = 'SPC_CHG_VALORISER'
SET @v_retour = @CODE_OK
SET @v_valorisation = NULL
SET @v_prix_tonne = NULL

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


	/*Calcul de la valorisation, basé sur l'IDFournisseur et le poids reel*/
	--Récupération de l'ID fournisseur et du SFC_PRIX_TONNE correspondant
	SELECT @v_prix_tonne = SCF_PRIX_TONNE, @v_poids = SPC_CHARGE_BOBINE.SCB_POIDS_NET from SPC_CHG_FOURNISSEUR
		inner join SPC_CHARGE_BOBINE on SCB_IDFOURNISSEUR = SCF_IDFOURNISSEUR
		where SCB_IDCHARGE = @v_idcharge
	
	IF @v_prix_tonne IS NOT NULL
		AND @v_poids IS NOT NULL
	BEGIN
		SET @v_valorisation = @v_prix_tonne * @v_poids /1000
			IF @v_valorisation IS NOT NULL
			BEGIN
				UPDATE SPC_CHARGE_BOBINE set SCB_VALORISATION = @v_valorisation
			END
			ELSE
			BEGIN
				set @chaineTrace = 'Valorisation KO de la charge : @v_idcharge' + CONVERT (varchar, ISNULL(@v_idcharge,''))
						+ ' , Valorisation nulle'
				EXECUTE INT_ADDTRACESPECIFIQUE @v_transaction, 'ERREUR', @chaineTrace				
				SET @v_retour =  @CODE_KO
			END
	END
	ELSE
	BEGIN
		set @chaineTrace = 'Valorisation KO de la charge : @v_idcharge' + CONVERT (varchar, ISNULL(@v_idcharge,''))
				+ ' ,@v_prix_tonne' + CONVERT (varchar, ISNULL(@v_prix_tonne,''))
				+ ' ,@v_poids' + CONVERT (varchar, ISNULL(@v_poids,''))
		EXECUTE INT_ADDTRACESPECIFIQUE @v_transaction, 'ERREUR', @chaineTrace				
		SET @v_retour =  @CODE_KO
	END

		
-- Gestion des fermetures de transactions
-----------------------------------------
	IF @v_retour <> @CODE_OK
	BEGIN
		IF @v_local = 1
			ROLLBACK TRAN @v_transaction
	END
	ELSE IF @v_local = 1
		COMMIT TRAN @v_transaction
	RETURN @v_retour

END

