SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Horloge de simulation
-- =============================================
CREATE PROCEDURE [dbo].[SPC_SIMU_HORLOGE]
	@p_numeroMessage   int, 
	@p_typeMessage     int,
	@p_horodateMessage datetime,
	@p_abonneInterne   int,
	@p_abonneExterne   int,
	@p_intervalle      int
AS
BEGIN
	declare @CODE_OK int = 0,
			@CODE_KO int = 1
	
	declare @retour int
	declare	@procStock varchar(128) = 'SPC_SIMU_HORLOGE'
	declare @chaineTrace varchar(7500)
	declare @v_idcharge int
	declare @rand int

	select TOP 1 @v_idcharge = CHG_IDCHARGE from INT_CHARGE_VIVANTE
		inner join INT_ADRESSE on ADR_IDSYSTEME = CHG_IDSYSTEME and ADR_IDBASE = CHG_IDBASE and ADR_IDSOUSBASE = CHG_IDSOUSBASE
		where ADR_MAGASIN = 3 and ADR_ALLEE = 1 and ADR_COULOIR in (5,6)
	IF @@rowcount <> 0
		exec INT_DELETECHARGE @v_idcharge

	IF @p_abonneInterne = -3
	BEGIN
		set @rand = ROUND(RAND()*10,0)

		/*Simulation de la rentrée en stock*/
		--IF @rand BETWEEN 5 and 10
		IF NOT EXISTS (SELECT 1 from INT_CHARGE_VIVANTE where CHG_IDSYSTEME = 65793 and CHG_IDBASE =144116291882516737 and CHG_IDSOUSBASE = 65793)
			exec dbo.SPC_SIMU_RECEPTION
		
		IF @rand BETWEEN 0 and 1
			exec SPC_SIMU_DEMAC
	END
END
